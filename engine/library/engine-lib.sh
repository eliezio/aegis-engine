#!/bin/bash

# ============LICENSE_START=======================================================
#  Copyright (C) 2019 The Nordix Foundation. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
# ============LICENSE_END=========================================================

set -o pipefail

# TODO: ignoring SC2015 for the timebeing so we don't break things
# shellcheck disable=SC2015
# Avoid double sourcing the file
[[ -n ${ENGINE_LIB_SOURCED:-} ]] && return 0 || export ENGINE_LIB_SOURCED=1

#-------------------------------------------------------------------------------
# Check some prerequisites before proceeding further.
# Any other check that could be fatal for script to continue should be checked
# here so we quite as early as possible. Current checks are
# - the user shall not be root
# - the ssh keypair shall be created in advance
# - env_reset shall not be present
#-------------------------------------------------------------------------------
function check_prerequisites() {

  echo "Info  : Check prerequisites"

  #-------------------------------------------------------------------------------
  # We shouldn't be running as root
  #-------------------------------------------------------------------------------
  if [[ "$(whoami)" == "root" ]]; then
    echo "ERROR : This script must not be run as root!"
    echo "        Please switch to a regular user before running the script."
    exit 1
  fi

  #-------------------------------------------------------------------------------
  # Check if SSH key exists
  #-------------------------------------------------------------------------------
  if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo "ERROR : You must have SSH keypair in order to run this script!"
    exit 1
  fi

  #-------------------------------------------------------------------------------
  # We are using sudo so we need to make sure that env_reset is not present
  #-------------------------------------------------------------------------------
  sudo sed -i "s/^Defaults.*env_reset/#&/" /etc/sudoers

}

#-------------------------------------------------------------------------------
# Set few environment variables and source the other files that have additional
# environment variables set in them for further use
#-------------------------------------------------------------------------------
function bootstrap_environment() {

  echo "Info  : Prepare environment for Cloud Infra $EXECUTION_MODE"

  # source engine-vars
  # shellcheck source=engine/library/engine-vars.sh
  source "$ENGINE_PATH/engine/library/engine-vars.sh"

  # Make sure we pass ENGINE_PATH everywhere
  ENGINE_ANSIBLE_PARAMS+=" -e engine_path=${ENGINE_PATH}"

  # Convert to array to allow quoting of ENGINE_ANSIBLE_PARAMS
  read -r -a ENGINE_ANSIBLE_PARAMS <<< "$(echo -e "${ENGINE_ANSIBLE_PARAMS}")"
  export ENGINE_ANSIBLE_PARAMS

  # Make sure everybody knows where our global roles are
  export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles"

  # Update path
  if ! grep -q "$HOME/.local/bin" <<< "$PATH"; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  # Create engine workspace directory
  sudo mkdir -p "${ENGINE_WORKSPACE}"
  sudo chown "${USER}:${USER}" "${ENGINE_WORKSPACE}"

}

#-------------------------------------------------------------------------------
# In order to install Ansible on the host, few packages need to be installed
# before that. This function determines the distro specific package names
# by mapping them to the package list, installs them and continues with
# Ansible and other Python package installations. The installation of Python
# packages are done in Virtualenv.
# In order to protect ourselves from issues that could come from upstream,
# OpenStack Upper Constraints is used so we install what is tested/verified.
#-------------------------------------------------------------------------------
function install_ansible() {

  set -eu

  local install_map

  declare -A PKG_MAP

  export LANG="C"

  # we only install the most basic dependencies outside of bindep.txt
  CHECK_CMD_PKGS=(
    venv
    python
  )

  # shellcheck source=/etc/os-release
  source /etc/os-release || source /usr/lib/os-release
  case ${ID,,} in
    ubuntu|debian)
      OS_FAMILY="Debian"
      export DEBIAN_FRONTEND=noninteractive
      PKG_MGR=apt
      INSTALLER_CMD="sudo -H -E apt install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew"
      PKG_MAP=(
        [python]=python3-minimal
        [venv]=virtualenv
      )
      redirect_cmd sudo apt update

      ;;

    *) echo "ERROR : Supported package manager not found.  Supported: apt, dnf, yum, zypper"; exit 1;;
  esac

  # Build installation map
  for pkgmap in "${CHECK_CMD_PKGS[@]}"; do
    install_map+=( "${PKG_MAP[$pkgmap]}" )
  done

  echo "Info  : Install ${install_map[*]} using $PKG_MGR on jumphost"
  # shellcheck disable=SC2068 disable=SC2086
  redirect_cmd ${INSTALLER_CMD} ${install_map[@]}

  echo "Info  : Prepare virtual environment at $ENGINE_VENV on jumphost"
  # We need to prepare our virtualenv now
  if [[ "${EXECUTION_MODE}" == "offline-deployment" ]]; then
    redirect_cmd virtualenv --python python3 --never-download "${ENGINE_VENV}"
    # Configure pip options to force offline operations
    cp "${ENGINE_WORKSPACE}/offline/pip/pip.conf" "${ENGINE_VENV}"
  else
    redirect_cmd virtualenv --python python3 --no-site-packages "${ENGINE_VENV}"
  fi
  # NOTE: venv is created during runtime so shellcheck SC1090 is disabled
  set +u
  # shellcheck disable=SC1090
  source "${ENGINE_VENV}/bin/activate"
  set -u

  if [[ "${EXECUTION_MODE}" == "offline-deployment" ]]; then
    echo "Info  : Upgrading pip in offline mode"
    redirect_cmd pip install --upgrade pip
  fi

  # since we use bindep.txt to control distro packages to install, we need to install bindep first using pip
  echo "Info  : Install bindep using pip"
  redirect_cmd pip install --upgrade bindep

  echo "Info  : Install system packages listed in bindep.txt using $PKG_MGR"
  cd "$ENGINE_PATH"
  # bindep -b exits with non-zero if it identifies a missing package so we disable pipefail
  set +o pipefail
  # shellcheck disable=SC2046 disable=SC2086
  bindep -b &> /dev/null || redirect_cmd ${INSTALLER_CMD} $(bindep -b)
  set -o pipefail

  # TODO (fdegir): installation of pip packages fail due to not being able to find setuptools
  # as build dependency so we do --no-use-pep517 as workaround.
  # This needs to be revisited later on.
  echo "Info  : Install python packages listed in requirements.txt using pip"
  redirect_cmd pip install --no-use-pep517 --force-reinstall -r requirements.txt

  # NOTE (fdegir): We need to profile packaging and deployments to identify what takes
  # time and perhaps attempt to fix it thus ara could become handy
  ANSIBLE_CALLBACK_PLUGINS="$(python3 -m ara.setup.callback_plugins)"
  export ANSIBLE_CALLBACK_PLUGINS

  if [[ "$OS_FAMILY" == "Debian" ]]; then
    # Get python3-apt and install into venv
    # shellcheck disable=SC2125
    venv_site_packages_dir="${ENGINE_VENV}"/lib/python3*/site-packages
    tempdir=$(mktemp -d)

    cd "$tempdir"
    echo "Info  : Download and install python3-apt using apt"
    redirect_cmd apt download python3-apt

    dpkg -x python3-apt_*.deb python3-apt
    chown -R "$USER:$USER" "$tempdir"/python3-apt/usr/lib/python3*/dist-packages

    # NOTE: we want the globbing
    # shellcheck disable=SC2086
    cp -r "$tempdir"/python3-apt/usr/lib/python3*/dist-packages/* $venv_site_packages_dir
    # NOTE: we want the globbing
    # shellcheck disable=SC2086
    cd $venv_site_packages_dir
    mv apt_pkg.*.so apt_pkg.so
    mv apt_inst.*.so apt_inst.so

    rm -rf "$tempdir"
  fi

}

#-------------------------------------------------------------------------------
# In some cases, it is useful to see all the output generated by commands so
# this function makes it possible for users to achieve that by not redirecting
# output to /dev/null when verbosity is enabled
#-------------------------------------------------------------------------------
redirect_cmd() {

  if [[ "$VERBOSITY" == "false" ]]; then
    "$@" > /dev/null 2>&1
  else
    "$@"
  fi

}

# vim: set ts=2 sw=2 expandtab:

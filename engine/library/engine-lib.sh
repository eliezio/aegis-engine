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
# Print the help message which includes the usage, the expected parameters
# and their default values if they are not specified
#-------------------------------------------------------------------------------
function usage() {
    # NOTE: shellcheck complains quoting in the example so SC2086 is disabled
    # shellcheck disable=SC2086
    cat <<EOF

Usage: $(basename ${0}) [-d <installer type>] [-r <provisioner type>] [-s <scenario>] [-b <scenario baseline file>] [-o <operating system>] [-p <pod descriptor file>] [-i <installer decriptor file>] [-e <heat environment file>] [-l "<provision>,<installer>"] [-v] [-c] [-h]

    -d: Installer type to use for deploying selected scenario. (Default kubespray)
    -r: Provisioner type to use for provisioning nodes. (Default bifrost)
    -s: Scenario which the SUT is deployed with. (Default k8-calico-nofeature)
    -b: URI to Scenario Baseline File. (SDF) (Default file://\$ENGINE_PATH/engine/inventory/group_vars/all/sdf.yaml)
    -p: URI to POD Descriptor File (PDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml)
    -i: URI to Installer Descriptor File (IDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml)
    -u: If provisioner is Heat, path to OpenStack openrc file. (No default)
    -e: URI to OpenStack Heat Environment File specific to cloud and scenario. (Default https://gerrit.nordix.org/gitweb?p=infra/engine.git;a=blob_plain;f=engine/provisioner/heat/playbooks/roles/bootstrap-hwconfig/files/heat-environment.yaml)
    -o: Operating System to provision nodes with. (Default ubuntu1804)
    -l: List of stages to run in a comma separated fashion. (Default execute all)
    -v: Increase verbosity and keep logs for troubleshooting. (Default false)
    -x: Enable offline installation. Requires offline dependencies to be present in the machine. (Default false)
    -c: Wipeout leftovers before execution. (Default false)
    -h: This message.

EOF
    exit 0
}

#-------------------------------------------------------------------------------
# Parse the arguments that are passed to the script
# If an argument is not specified, default values for those are set
#
# The priority order is
# - arguments: overrides the default values and values set as environment
#   values. highest prio.
# - env vars: overrides the default values but not the values set from command
#   line.
# - default values: only takes effect if the user doesn't specify the value
#   of an argument either as an env var or from command line. lowest prio.
#-------------------------------------------------------------------------------
function parse_cmdline_opts() {
    # set variables to the values set in env - otherwise, set them to defaults
    INSTALLER_TYPE=${INSTALLER_TYPE:-kubespray}
    PROVISIONER_TYPE=${PROVISIONER_TYPE:-bifrost}
    DEPLOY_SCENARIO=${DEPLOY_SCENARIO:-k8-calico-nofeature}
    SDF=${SDF:-"file://${ENGINE_PATH}/engine/inventory/group_vars/all/sdf.yaml"}
    DISTRO=${DISTRO:-ubuntu1804}
    PDF=${PDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml"}
    IDF=${IDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml"}
    HEAT_ENV_FILE=${HEAT_ENV_FILE:-"https://gerrit.nordix.org/gitweb?p=infra/engine.git;a=blob_plain;f=engine/provisioner/heat/playbooks/roles/bootstrap-hwconfig/files/heat-environment.yaml"}
    DO_PROVISION=${DO_PROVISION:-1}
    DO_INSTALL=${DO_INSTALL:-1}
    DEPLOY_STAGE_LIST=${DEPLOY_STAGE_LIST:-""}
    CLEANUP=${CLEANUP:-false}
    VERBOSITY=${VERBOSITY:-false}
    OFFLINE_DEPLOYMENT=${OFFLINE_DEPLOYMENT:-false}

    # get values passed as command line arguments, overriding the defaults or
    # the ones set by using env variables
    while getopts ":hd:r:s:b:o:p:i:e:u:l:cvx" o; do
        case "${o}" in
            h) usage ;;
            d) INSTALLER_TYPE="${OPTARG}" ;;
            r) PROVISIONER_TYPE="${OPTARG}" ;;
            s) DEPLOY_SCENARIO="${OPTARG}" ;;
            b) SDF="${OPTARG}" ;;
            o) DISTRO="${OPTARG}" ;;
            p) PDF="${OPTARG}" ;;
            i) IDF="${OPTARG}" ;;
            e) HEAT_ENV_FILE="${OPTARG}" ;;
            u) OPENRC="${OPTARG}" ;;
            c) CLEANUP="true" ;;
            v) VERBOSITY="true" ;;
            l) DEPLOY_STAGE_LIST="${OPTARG}" ;;
            x) OFFLINE_DEPLOYMENT="true" ;;
            *) echo "ERROR : Invalid option '-${OPTARG}'"; usage ;;
        esac
    done

    # if provisioner type is heat, we need openrc as well
    if [[ "$PROVISIONER_TYPE" == "heat" && -z "${OPENRC:-}" ]]; then
      echo "ERROR : You must provide path to openrc file in order to use Heat as provisioner!"
      exit 1
    fi

    # check if specified openrc exists
    if [[ "$PROVISIONER_TYPE" == "heat" && ! -f $OPENRC ]]; then
      echo "ERROR : Specified openrc file '$OPENRC' does not exist!"
      exit 1
    fi

    # check the stages enabled in DEPLOY_STAGE_LIST
    if [[ -n "$DEPLOY_STAGE_LIST" ]]; then
      DO_PROVISION=$(echo "$DEPLOY_STAGE_LIST" | grep -c provision || true)
      DO_INSTALL=$(echo "$DEPLOY_STAGE_LIST" | grep -c installer || true)
    fi

    # Do all the exports
    export INSTALLER_TYPE="${INSTALLER_TYPE}"
    export PROVISIONER_TYPE="${PROVISIONER_TYPE}"
    export DEPLOY_SCENARIO="${DEPLOY_SCENARIO}"
    export SDF="${SDF}"
    export DISTRO="${DISTRO}"
    export PDF="${PDF}"
    export IDF="${IDF}"
    export HEAT_ENV_FILE="${HEAT_ENV_FILE}"
    export DO_PROVISION="${DO_PROVISION}"
    export DO_INSTALL="${DO_INSTALL}"
    export CLEANUP="${CLEANUP}"
    export OFFLINE_DEPLOYMENT="${OFFLINE_DEPLOYMENT}"
    export VERBOSITY="${VERBOSITY}"

    log_summary
}

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
    echo "Info  : Prepare environment for Cloud Infra deployment"

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
# Remove leftovers of previous runs
# Leftovers of previous run might result in failures, especially within CI/CD
# so this function is important to use but it is not executed by default.
#-------------------------------------------------------------------------------
function cleanup() {

    # skip cleanup if not requested
    if [[ "${CLEANUP}" != "true" ]]; then
        return 0
    fi

    echo "Info  : Remove leftovers of previous run"

    # remove engine venv, cache and .ansible
    sudo /bin/rm -rf "$ENGINE_VENV" "$ENGINE_CACHE" "$HOME/.ansible" \
        /tmp/offline-package

    # stop docker service since docker registry keeps creating
    # $ENGINE_CACHE/certs folder, making engine prep to fail due
    # to ownership issus
    sudo systemctl stop docker > /dev/null 2>&1 || true

    # stop ironic-conductor service before dropping ironic database
    sudo systemctl stop ironic-conductor > /dev/null 2>&1 || true

    # remove ironic and inspector database
    if command -v mysql &> /dev/null; then
        sudo mysql --execute "drop database ironic;" > /dev/null 2>&1 || true
        sudo mysql --execute "drop database inspector;" > /dev/null 2>&1 || true
    fi

    # restart ironic services
    sudo systemctl restart ironic-api > /dev/null 2>&1 || true
    sudo systemctl restart ironic-conductor > /dev/null 2>&1 || true
    sudo systemctl restart ironic-inspector > /dev/null 2>&1 || true

    # in some cases, apt-get purge complains with "E: Unable to locate package rabbitmq-server"
    # and exits 100, causing this script and deploy.sh to fail.
    # run apt-get update to get rid of this
    # This is not needed in offline installation mode and apt will fail since the proxy/mirror
    # is not configured yet
    if [[ "${OFFLINE_DEPLOYMENT}" == "false" ]]; then
      sudo apt-get update -qq
      # clean and remove rabbitmq service
      sudo apt-get purge --auto-remove -y -qq rabbitmq-server > /dev/null
    fi
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
        INSTALLER_CMD="sudo -H -E apt install -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew -q=3"
        PKG_MAP=(
            [python]=python3-minimal
            [venv]=virtualenv
        )
        sudo apt update -q=3 > /dev/null 2>&1

        ;;

        *) echo "ERROR : Supported package manager not found.  Supported: apt, dnf, yum, zypper"; exit 1;;
    esac

    # Build installation map
    for pkgmap in "${CHECK_CMD_PKGS[@]}"; do
        install_map+=( "${PKG_MAP[$pkgmap]}" )
    done

    echo "Info  : Install ${install_map[*]} using $PKG_MGR on jumphost"
    # shellcheck disable=SC2068
    ${INSTALLER_CMD} ${install_map[@]} > /dev/null 2>&1

    echo "Info  : Prepare virtual environment at $ENGINE_VENV on jumphost"
    # We need to prepare our virtualenv now
    if [[ "${OFFLINE_DEPLOYMENT}" == "true" ]]; then
      virtualenv --python python3 --quiet --never-download "${ENGINE_VENV}" > /dev/null 2>&1
      # Configure pip options to force offline operations
      cp "${ENGINE_CACHE}/offline/pip/pip.conf" "${ENGINE_VENV}"
    else
      virtualenv --python python3 --quiet --no-site-packages "${ENGINE_VENV}" > /dev/null 2>&1
    fi
    # NOTE: venv is created during runtime so shellcheck SC1090 is disabled
    set +u
    # shellcheck disable=SC1090
    source "${ENGINE_VENV}/bin/activate"
    set -u

    # Pip might come by default with an old version that does not have the
    # --no-color option making the following commands fail
    if [[ "${OFFLINE_DEPLOYMENT}" == "true" ]]; then
      echo "Info  : Upgrading pip in offline mode"
      pip install --upgrade --quiet pip
    fi

    # since we use bindep.txt to control distro packages to install, we need to install bindep first using pip
    echo "Info  : Install bindep using pip"
    pip install --upgrade --no-color --quiet bindep

    echo "Info  : Install system packages listed in bindep.txt using $PKG_MGR"
    cd "$ENGINE_PATH"
    # bindep -b exits with non-zero if it identifies a missing package so we disable pipefail
    set +o pipefail
    # shellcheck disable=SC2046
    bindep -b &> /dev/null || ${INSTALLER_CMD} $(bindep -b) > /dev/null 2>&1
    set -o pipefail

    echo "Info  : Install python packages listed in requirements.txt using pip"
    pip install --force-reinstall --no-color --quiet -r requirements.txt

    if [[ "$OS_FAMILY" == "Debian" ]]; then
      # Get python3-apt and install into venv
      # shellcheck disable=SC2125
      venv_site_packages_dir="${ENGINE_VENV}"/lib/python3*/site-packages
      cd /tmp
      echo "Info  : Download and install python3-apt using apt"
      apt download -q=3 python3-apt > /dev/null 2>&1

      dpkg -x python3-apt_*.deb python3-apt
      chown -R "$USER:$USER" /tmp/python3-apt/usr/lib/python3*/dist-packages

      # NOTE: we want the globbing
      # shellcheck disable=SC2086
      cp -r /tmp/python3-apt/usr/lib/python3*/dist-packages/* $venv_site_packages_dir
      # NOTE: we want the globbing
      # shellcheck disable=SC2086
      cd $venv_site_packages_dir
      mv apt_pkg.*.so apt_pkg.so
      mv apt_inst.*.so apt_inst.so

      rm -rf /tmp/python3-apt*
    fi
}

#-------------------------------------------------------------------------------
# Log summary & parameters to console
#-------------------------------------------------------------------------------
function log_summary() {
    echo
    echo "#---------------------------------------------------#"
    echo "#                   Environment                     #"
    echo "#---------------------------------------------------#"
    echo "User         : $USER"
    echo "Hostname     : $HOSTNAME"
    echo "Host OS      : $(source /etc/os-release &> /dev/null || source /usr/lib/os-release &> /dev/null; echo "${PRETTY_NAME}")"
    echo "IP           : $(hostname -I | cut -d' ' -f1)"
    echo
    echo "#---------------------------------------------------#"
    echo "#                Deployment Started                 #"
    echo "#---------------------------------------------------#"
    echo "Date & Time    : $(date -u '+%F %T UTC')"
    if [[ "$OFFLINE_DEPLOYMENT" == "true" ]]; then
      echo "Execution Mode : Offline deployment"
    else
      echo "Execution mode : Online deployment"
    fi
    echo "Scenario       : $DEPLOY_SCENARIO"
    echo "Target OS      : $DISTRO"
    echo "Installer      : $INSTALLER_TYPE"
    echo "Provisioner    : $PROVISIONER_TYPE"
    if [[ "$PROVISIONER_TYPE" == "heat" ]]; then
      echo "Openrc File    : $OPENRC"
      echo "Heat Env File  : $HEAT_ENV_FILE"
    else
      echo "PDF            : $PDF"
      echo "IDF            : $IDF"
    fi
    echo "SDF            : $SDF"
    echo "Cleanup        : $CLEANUP"
    echo "Verbosity      : $VERBOSITY"
    echo "#---------------------------------------------------#"
    echo

}

#-------------------------------------------------------------------------------
# Log elapsed time to console
#-------------------------------------------------------------------------------
function log_elapsed_time() {
    elapsed_time=$SECONDS
    echo "#---------------------------------------------------#"
    echo "#                Deployment Completed               #"
    echo "#---------------------------------------------------#"
    echo "Date & Time  : $(date -u '+%F %T UTC')"
    echo "Elapsed      : $((elapsed_time / 60)) minutes and $((elapsed_time % 60)) seconds"
    echo "#---------------------------------------------------#"
}

#-------------------------------------------------------------------------------
# Prepare offline installation
#-------------------------------------------------------------------------------
function prepare_offline() {

    # return without doing anything if it is not an offline deployment
    if [[ "$OFFLINE_DEPLOYMENT" != "true" ]]; then
        return 0
    fi

    # Offline mode requires dependencies to be present on the machine
    if [[ ! -f "$OFFLINE_PKG_FILE" ]]; then
        echo "ERROR : Offline dependencies file, $OFFLINE_PKG_FILE, does not exist!"
        echo "        You may want to run package.sh to package dependencies"
        exit 1
    fi

    # Create the offline folder and repository folder (not available yet)
    mkdir -p "$ENGINE_CACHE/offline"
    mkdir -p "$ENGINE_CACHE/repos"

    # Extract offline components
    echo "Info  : Preparing for offline deployment"
    tar -zxf "$OFFLINE_PKG_FILE" -C "$ENGINE_CACHE/offline"

    # Copy repos to engine default folder
    cp -r "$ENGINE_CACHE/offline/git/." "$ENGINE_CACHE/repos"

    # move apt cache to the directory which will become the root directory of web server
    rm -rf "$ENGINE_CACHE/www" && mkdir -p "$ENGINE_CACHE/www"
    mv -fi "$ENGINE_CACHE/offline/pkg" "$ENGINE_CACHE/www"

    # NOTE (fdegir): we don't have nginx yet so we use local directory
    # as the apt repository to continue with basic preperation
    sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo bash -c "echo deb [trusted=yes] file:$ENGINE_CACHE/www/pkg amd64/ > /etc/apt/sources.list"

    # run apt update to ensure our apt mirror works or we bail out before proceeding further
    sudo apt update > /dev/null 2>&1
}

# vim: set ts=2 sw=2 expandtab:

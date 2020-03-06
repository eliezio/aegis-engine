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
[[ -n ${DEPLOY_LIB_SOURCED:-} ]] && return 0 || export DEPLOY_LIB_SOURCED=1

#-------------------------------------------------------------------------------
# Print the help message which includes the usage, the expected parameters
# and their default values if they are not specified
#-------------------------------------------------------------------------------
function usage() {

  # NOTE: shellcheck complains quoting in the example so SC2086 is disabled
  # shellcheck disable=SC2086
  cat <<EOF

Usage: $(basename ${0}) [-d <installer type>] [-r <provisioner type>] [-s <scenario>] [-b <scenario baseline file>] [-o <operating system>] [-p <pod descriptor file>] [-i <installer decriptor file>] [-e <heat environment file>] [-l "<provision>,<installer>"] [-x] [-v] [-h]

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
  VERBOSITY=${VERBOSITY:-false}
  EXECUTION_MODE=${EXECUTION_MODE:-online-deployment}

  # get values passed as command line arguments, overriding the defaults or
  # the ones set by using env variables
  while getopts ":hd:r:s:b:o:p:i:e:u:l:vfx" o; do
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
      v) VERBOSITY="true" ;;
      l) DEPLOY_STAGE_LIST="${OPTARG}" ;;
      x) EXECUTION_MODE="offline-deployment" ;;
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
  export EXECUTION_MODE="${EXECUTION_MODE}"
  export VERBOSITY="${VERBOSITY}"
  export OFFLINE_INSTALLER_FILE="/tmp/k8s-installer-ubuntu1804.bsx"

  log_summary

}

#-------------------------------------------------------------------------------
# Remove leftovers of previous runs
# Leftovers of previous run might result in failures, especially within CI/CD
# so this function is important to use but it is not executed by default.
#-------------------------------------------------------------------------------
function cleanup() {

  echo "Info  : Remove leftovers of previous run"

  # remove engine venv, cache and .ansible
  sudo /bin/rm -rf "$ENGINE_VENV" "$ENGINE_CACHE" "$HOME/.ansible"

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
  if [[ "${EXECUTION_MODE}" == "online-deployment" ]]; then
    sudo apt-get update -qq
    # clean and remove rabbitmq service
    sudo apt-get purge --auto-remove -y -qq rabbitmq-server > /dev/null
  fi

}

#-------------------------------------------------------------------------------
# Log summary & parameters to console
#-------------------------------------------------------------------------------
function log_summary() {

  echo
  echo "#---------------------------------------------------#"
  echo "#                    Environment                    #"
  echo "#---------------------------------------------------#"
  echo "User             : $USER"
  echo "Hostname         : $HOSTNAME"
  echo "Host OS          : $(source /etc/os-release &> /dev/null || source /usr/lib/os-release &> /dev/null; echo "${PRETTY_NAME}")"
  echo "IP               : $(hostname -I | cut -d' ' -f1)"
  echo "#---------------------------------------------------#"
  echo "#                 Execution Started                 #"
  echo "#---------------------------------------------------#"
  echo "Date & Time      : $(date -u '+%F %T UTC')"
  echo "Execution Mode   : $EXECUTION_MODE"
  if [[ "$EXECUTION_MODE" == "offline-deployment" ]]; then
    echo "Offline Installer: $OFFLINE_INSTALLER_FILE"
  fi
  echo "Scenario         : $DEPLOY_SCENARIO"
  echo "Target OS        : $DISTRO"
  echo "Installer        : $INSTALLER_TYPE"
  echo "Provisioner      : $PROVISIONER_TYPE"
  if [[ "$PROVISIONER_TYPE" == "heat" ]]; then
    echo "Openrc File      : $OPENRC"
    echo "Heat Env File    : $HEAT_ENV_FILE"
  else
    echo "PDF              : $PDF"
    echo "IDF              : $IDF"
  fi
  echo "SDF              : $SDF"
  echo "Verbosity        : $VERBOSITY"
  echo "#---------------------------------------------------#"
  echo

}

#-------------------------------------------------------------------------------
# Log elapsed time to console
#-------------------------------------------------------------------------------
function log_elapsed_time() {

  elapsed_time=$SECONDS
  echo
  echo "#---------------------------------------------------#"
  echo "#                Execution Completed                #"
  echo "#---------------------------------------------------#"
  echo "Date & Time      : $(date -u '+%F %T UTC')"
  echo "Elapsed          : $((elapsed_time / 60)) minutes and $((elapsed_time % 60)) seconds"
  echo "#---------------------------------------------------#"
  echo

}

#-------------------------------------------------------------------------------
# Prepare offline installation
#-------------------------------------------------------------------------------
function prepare_offline() {

  # return without doing anything if it is not an offline deployment
  if [[ "$EXECUTION_MODE" != "offline-deployment" ]]; then
    return 0
  fi

  # Offline mode requires dependencies to be present on the machine
  if [[ ! -f "$ENGINE_WORKSPACE/offline/install.sh" ]]; then
    echo "ERROR : Offline dependencies do not exist on the machine!"
    echo "        You may want to run package.sh to package dependencies"
    exit 1
  fi

  echo "Info  : Placing packages and repositories in place for offline deployment"
  # Create the folder for repositories
  mkdir -p "$ENGINE_CACHE/repos"

  # Copy repos to engine default folder
  cp -rf "$ENGINE_WORKSPACE/offline/git/." "$ENGINE_CACHE/repos"

  # move apt cache to the directory which will become the root directory of web server
  mkdir -p "$ENGINE_CACHE/www"
  cp -rf "$ENGINE_WORKSPACE/offline/pkg" "$ENGINE_CACHE/www"

  # NOTE (fdegir): we don't have nginx yet so we use local directory
  # as the apt repository to continue with basic preperation
  sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.bak
  sudo bash -c "echo deb [trusted=yes] file:$ENGINE_CACHE/www/pkg amd64/ > /etc/apt/sources.list"

  # run apt update to ensure our apt mirror works or we bail out before proceeding further
  sudo apt update > /dev/null 2>&1

}

# vim: set ts=2 sw=2 expandtab:

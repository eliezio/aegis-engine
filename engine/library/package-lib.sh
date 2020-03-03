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
[[ -n ${PACKAGE_LIB_SOURCED:-} ]] && return 0 || export PACKAGE_LIB_SOURCED=1

#-------------------------------------------------------------------------------
# Print the help message which includes the usage, the expected parameters
# and their default values if they are not specified
#-------------------------------------------------------------------------------
function usage() {

  # NOTE: shellcheck complains quoting in the example so SC2086 is disabled
  # shellcheck disable=SC2086
  cat <<EOF

Usage: $(basename ${0}) [-h]

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

  # TODO (fdegir): This function is left here so we can introduce additional
  # arguments when we introduce support for other stacks than Kubernetes only
  # get values passed as command line arguments, overriding the defaults or
  # the ones set by using env variables
  while getopts ":h" o; do
    case "${o}" in
      h) usage ;;
      *) echo "ERROR: Invalid option '-${OPTARG}'"; usage ;;
    esac
  done

  # Do all the exports
  export EXECUTION_MODE="packaging"
  export OFFLINE_PKG_FILE="/tmp/offline-package.tgz"
  export OFFLINE_INSTALLER_FILE="/tmp/k8s-installer-ubuntu1804.bsx"

  # NOTE (fdegir): we currently support packaging and offline deployments
  # for Kubernetes. At the same time, we strive to package all the Kubernetes
  # scenarios so setting those variables here as well. Installer type will
  # probably need to be parameterized in future.
  export INSTALLER_TYPE="kubespray"
  export DEPLOY_SCENARIO="all"

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
  sudo /bin/rm -rf "$ENGINE_VENV" "$ENGINE_CACHE" "$HOME/.ansible" \
      "$OFFLINE_PKG_FOLDER" "$OFFLINE_PKG_FILE"

  # stop docker service since docker registry keeps creating
  # $ENGINE_CACHE/certs folder, making engine prep to fail due
  # to ownership issus
  sudo systemctl stop docker > /dev/null 2>&1 || true

}

#-------------------------------------------------------------------------------
# Log summary & parameters to console
#-------------------------------------------------------------------------------
function log_summary() {

  echo
  echo "#---------------------------------------------------#"
  echo "#                   Environment                     #"
  echo "#---------------------------------------------------#"
  echo "User             : $USER"
  echo "Hostname         : $HOSTNAME"
  echo "Host OS          : $(source /etc/os-release &> /dev/null || source /usr/lib/os-release &> /dev/null; echo "${PRETTY_NAME}")"
  echo "IP               : $(hostname -I | cut -d' ' -f1)"
  echo "#---------------------------------------------------#"
  echo "#                 Packaging Started                 #"
  echo "#---------------------------------------------------#"
  echo "Date & Time      : $(date -u '+%F %T UTC')"
  echo "Execution Mode   : packaging"
  echo "Offline Installer: $OFFLINE_INSTALLER_FILE"
  echo "#---------------------------------------------------#"

}

#-------------------------------------------------------------------------------
# Log elapsed time to console
#-------------------------------------------------------------------------------
function log_elapsed_time() {
  elapsed_time=$SECONDS
  echo "#---------------------------------------------------#"
  echo "#                Packaging Completed                #"
  echo "#---------------------------------------------------#"
  echo "Date & Time      : $(date -u '+%F %T UTC')"
  echo "Elapsed          : $((elapsed_time / 60)) minutes and $((elapsed_time % 60)) seconds"
  echo "#---------------------------------------------------#"
}

# vim: set ts=2 sw=2 expandtab:

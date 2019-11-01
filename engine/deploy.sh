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

set -o errexit
set -o nounset
set -o pipefail

#-------------------------------------------------------------------------------
# Getting ready to run
#-------------------------------------------------------------------------------
# Find/set where we are
export ENGINE_PATH="$(git rev-parse --show-toplevel)"

# source helpers library
source ${ENGINE_PATH}/engine/files/engine-lib.sh

#-------------------------------------------------------------------------------
# Parse command line options
#-------------------------------------------------------------------------------
parse_cmdline_opts $*

#-------------------------------------------------------------------------------
# Check prerequisites before doing anything else to see if we should continue
#-------------------------------------------------------------------------------
check_prerequisites

#-------------------------------------------------------------------------------
# Bootstrap environment for Cloud Infra Deployment
#-------------------------------------------------------------------------------
echo "Info: Preparing environment for Cloud Infra deployment"
bootstrap_environment

#-------------------------------------------------------------------------------
# Cleanup leftovers of previous run if it is explicitly set
#-------------------------------------------------------------------------------
if [[ "$CLEANUP" == "true" ]]; then
  echo "Info: Removing leftovers of previous run"
  cleanup
fi

#-------------------------------------------------------------------------------
# Install Ansible
#-------------------------------------------------------------------------------
echo "Info: Installing Ansible from pip on jumphost"
echo "-------------------------------------------------------------------------"
install_ansible
echo "-------------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# Bootstrap hwconfig and swconfig
#-------------------------------------------------------------------------------
echo "Info: Bootstrapping hardware and software configuration"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  engine/playbooks/bootstrap-configuration.yml
echo "-------------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# Source scenario overrides
#-------------------------------------------------------------------------------
source $(find ${SCENARIO_OVERRIDES} 2>/dev/null) &>/dev/null &&
  echo "Info: Sourced scenario overrides" || :

#-------------------------------------------------------------------------------
# Provision nodes using the selected provisioning tool
#-------------------------------------------------------------------------------
echo ${DO_PROVISION}
if [[ "${DO_PROVISION}" -eq 1 ]]; then
  source ${ENGINE_PATH}/engine/provisioner/${PROVISIONER_TYPE}/provision.sh
else
  echo "Provisioning flag not specified"
  exit 1
fi

#-------------------------------------------------------------------------------
# Install the stack using the selected installer
#-------------------------------------------------------------------------------
if [[ "${DO_INSTALLER}" -eq 1 ]]; then
  source ${ENGINE_PATH}/engine/installer/${INSTALLER_TYPE}/install.sh

  #-----------------------------------------------------------------------------
  # Install all the requested apps
  #-----------------------------------------------------------------------------
  apps=($(echo ${APPS} | tr "," "\n"))
  for app in "${apps[@]}"
  do
    app_playbook="${APPS_PATH}/$app/${INSTALLER_TYPE}/playbooks/install.yml"
    ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
      -i ${ENGINE_CACHE}/config/inventory.ini \
      $app_playbook
  done

else
  echo "No installer selected"
fi

#-------------------------------------------------------------------------------
# Log total time it took to finish to console
#-------------------------------------------------------------------------------
log_elapsed_time

# vim: set ts=2 sw=2 expandtab:

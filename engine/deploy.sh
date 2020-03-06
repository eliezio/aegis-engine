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
# Find and set where we are
#-------------------------------------------------------------------------------
ENGINE_PATH=$(git rev-parse --show-toplevel)
export ENGINE_PATH

#-------------------------------------------------------------------------------
# Source deploy and engine libraries
#-------------------------------------------------------------------------------
# shellcheck source=engine/library/deploy-lib.sh
source "${ENGINE_PATH}/engine/library/deploy-lib.sh"
# shellcheck source=engine/library/engine-lib.sh
source "${ENGINE_PATH}/engine/library/engine-lib.sh"

#-------------------------------------------------------------------------------
# Parse command line options
#-------------------------------------------------------------------------------
parse_cmdline_opts "$@"

#-------------------------------------------------------------------------------
# Check prerequisites before doing anything else to see if we should continue
#-------------------------------------------------------------------------------
check_prerequisites

#-------------------------------------------------------------------------------
# Bootstrap environment for Cloud Infra Deployment
#-------------------------------------------------------------------------------
bootstrap_environment

#-------------------------------------------------------------------------------
# Cleanup leftovers of previous run if it is explicitly set
#-------------------------------------------------------------------------------
cleanup

#-------------------------------------------------------------------------------
# Prepare for offline deployment
#-------------------------------------------------------------------------------
prepare_offline

#-------------------------------------------------------------------------------
# Install Ansible
#-------------------------------------------------------------------------------
install_ansible

#-------------------------------------------------------------------------------
# Bootstrap swconfig
#-------------------------------------------------------------------------------
echo "Info  : Bootstrap software configuration"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
    -i "${ENGINE_PATH}/engine/inventory/localhost.ini" \
    engine/playbooks/bootstrap-swconfig.yaml
echo "-------------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# Source scenario overrides
#-------------------------------------------------------------------------------
# NOTE: shellcheck SC1090 is disabled since overrides file is put in place during runtime
# shellcheck disable=SC1090
if [[ -f "${SCENARIO_OVERRIDES}" ]]; then
  source "${SCENARIO_OVERRIDES}"
  echo "Info  : Source scenario overrides"
fi

#-------------------------------------------------------------------------------
# Provision nodes using the selected provisioning tool
#-------------------------------------------------------------------------------
if [[ "${DO_PROVISION}" -eq 1 ]]; then
  # NOTE: the default provisioner is bifrost so we point it to shellcheck as source
  # shellcheck source=engine/provisioner/bifrost/provision.sh
  source "${ENGINE_PATH}/engine/provisioner/${PROVISIONER_TYPE}/provision.sh"
else
  echo "ERROR : Provisioning flag not specified"
  exit 1
fi

#-------------------------------------------------------------------------------
# Provision local apt repo, docker registry, and ntp server services
#-------------------------------------------------------------------------------
if [[ "${EXECUTION_MODE}" == "offline-deployment" ]]; then
  echo "Info  : Provision local services"
  echo "-------------------------------------------------------------------------"
  cd "${ENGINE_PATH}"
  ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
      -i "${ENGINE_PATH}/engine/inventory/inventory.ini" \
      engine/playbooks/provision-local-services.yaml
  echo "-------------------------------------------------------------------------"
fi

#-------------------------------------------------------------------------------
# Install the stack using the selected installer
#-------------------------------------------------------------------------------
if [[ "${DO_INSTALL}" -eq 1 ]]; then
  # NOTE: the default installer is kubespray so we point it to shellcheck as source
  # shellcheck source=engine/installer/kubespray/install.sh
  source "${ENGINE_PATH}/engine/installer/${INSTALLER_TYPE}/install.sh"

  #-----------------------------------------------------------------------------
  # Install all the curated apps
  #-----------------------------------------------------------------------------
  echo "-------------------------------------------------------------------------"
  echo "Info  : Install curated apps on stack"
  echo "-------------------------------------------------------------------------"

  cd "${APPS_PATH}"
  ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
      -i "${ENGINE_PATH}/engine/inventory/inventory.ini" \
      install-apps.yml
else
  echo "Warning: No installer selected!"
fi

#-------------------------------------------------------------------------------
# Log total time it took to finish to console
#-------------------------------------------------------------------------------
log_elapsed_time

# vim: set ts=2 sw=2 expandtab:

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
ENGINE_PATH=$(git rev-parse --show-toplevel)
export ENGINE_PATH

# source helpers library
# shellcheck source=engine/files/engine-lib.sh
source "${ENGINE_PATH}/engine/files/engine-lib.sh"

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
if [[ "${CLEANUP}" == "true" ]]; then
  cleanup
fi

#-------------------------------------------------------------------------------
# Install Ansible
#-------------------------------------------------------------------------------
install_ansible

#-------------------------------------------------------------------------------
# Bootstrap hwconfig and swconfig
#-------------------------------------------------------------------------------
echo "Info: Bootstrap hardware and software configuration"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
    engine/playbooks/bootstrap-configuration.yml
echo "-------------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# Source scenario overrides
#-------------------------------------------------------------------------------
# NOTE: shellcheck SC1090 is disabled since overrides file is put in place during runtime
# shellcheck disable=SC1090
if [[ -f "${SCENARIO_OVERRIDES}" ]]; then
  source "${SCENARIO_OVERRIDES}"
  echo "Info: Source scenario overrides"
fi

#-------------------------------------------------------------------------------
# Provision nodes using the selected provisioning tool
#-------------------------------------------------------------------------------
if [[ "${DO_PROVISION}" -eq 1 ]]; then
  # NOTE: the default provisioner is bifrost so we point it to shellcheck as source
  # shellcheck source=engine/provisioner/bifrost/provision.sh
  source "${ENGINE_PATH}/engine/provisioner/${PROVISIONER_TYPE}/provision.sh"
else
  echo "Error: Provisioning flag not specified"
  exit 1
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
  cd "${APPS_PATH}"
  ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
    -i "${ENGINE_CACHE}/config/inventory.ini" \
    install-apps.yml
else
  echo "Warning: No installer selected!"
fi

#-------------------------------------------------------------------------------
# Log total time it took to finish to console
#-------------------------------------------------------------------------------
log_elapsed_time

# vim: set ts=2 sw=2 expandtab:

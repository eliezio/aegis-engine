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

PROVISIONER_ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles:${ENGINE_CACHE}/repos/bifrost/playbooks/roles"
export ANSIBLE_LIBRARY="$HOME/.ansible/plugins/modules:/usr/share/ansible/plugins/modules"

# set the BAREMETAL variable
export BAREMETAL=false

# NOTE: shellcheck SC1090 is disabled since openrc file is put in place during runtime
# source openrc file
# shellcheck disable=SC1090
source "$OPENRC"

#-------------------------------------------------------------------------------
# Bootstrap hwconfig
#-------------------------------------------------------------------------------
echo "Info: Bootstrap hardware configuration"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
    -i "${ENGINE_PATH}/engine/inventory/localhost.ini" \
    "${PROVISIONER_ROOT_DIR}/playbooks/bootstrap-hwconfig.yaml"

echo "Info: Create stack using Heat"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
    -i "${ENGINE_PATH}/engine/inventory/localhost.ini" \
    "${PROVISIONER_ROOT_DIR}/playbooks/create-stack.yaml"

echo "Info: Generate Ansible inventory"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
    -i "${ENGINE_PATH}/engine/inventory/localhost.ini" \
    "${PROVISIONER_ROOT_DIR}/playbooks/generate-inventory.yml"

echo "-------------------------------------------------------------------------"
echo "Info: Nodes are provisioned using OpenStack Heat!"
echo "-------------------------------------------------------------------------"

# vim: set ts=2 sw=2 expandtab:

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

BIFROST_ROOT_DIR="$(dirname $(realpath ${BASH_SOURCE[0]}))"
export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles:${ENGINE_CACHE}/repos/bifrost/playbooks/roles"
export ANSIBLE_LIBRARY="$HOME/.ansible/plugins/modules:/usr/share/ansible/plugins/modules:${ENGINE_CACHE}/repos/bifrost/playbooks/library"

# set the BAREMETAL variable
grep -o vendor.* ${ENGINE_CACHE}/config/pdf.yml | grep -q libvirt && export BAREMETAL=false || export BAREMETAL=true

# if we are not doing baremetal provisioning and deployment, we need to prepare
# the node for virtual deployment by installing dependencies, creating libvirt
# networks, vms, and the rest of the necesssary stuff
if [[ "$BAREMETAL" != "true" ]]; then
  echo "Info: Create libvirt resources for virtual deployment"
  echo "-------------------------------------------------------------------------"
  cd ${ENGINE_PATH}
  ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
    -i localhost, \
    ${BIFROST_ROOT_DIR}/playbooks/create-libvirt-resources.yml
fi

# install and configure bifrost
echo "-------------------------------------------------------------------------"
echo "Info: Prepare bifrost installation and create bifrost inventory"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i localhost, \
  ${BIFROST_ROOT_DIR}/playbooks/install-configure-bifrost.yml

echo "-------------------------------------------------------------------------"
echo "Info: Install bifrost"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/bifrost/playbooks
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i inventory/target \
  bifrost-install.yml

echo "-------------------------------------------------------------------------"
echo "Info: Enroll nodes using bifrost"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/bifrost/playbooks
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i inventory/bifrost_inventory.py \
  bifrost-enroll.yml

echo "-------------------------------------------------------------------------"
echo "Info: Deploy nodes using bifrost"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/bifrost/playbooks
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i inventory/bifrost_inventory.py \
  bifrost-deploy.yml

echo "-------------------------------------------------------------------------"
echo "Info: Nodes are provisioned using bifrost!"
echo "-------------------------------------------------------------------------"

# vim: set ts=2 sw=2 expandtab:

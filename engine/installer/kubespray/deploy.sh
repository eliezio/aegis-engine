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

INSTALLER_ROOT_DIR="$(dirname $(realpath ${BASH_SOURCE[0]}))"
export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles:${ENGINE_CACHE}/repos/bifrost/playbooks/roles"
export ANSIBLE_LIBRARY="$HOME/.ansible/plugins/modules:/usr/share/ansible/plugins/modules:${ENGINE_CACHE}/repos/bifrost/playbooks/library"

# configure target hosts
echo "-------------------------------------------------------------------------"
echo "Info: Configure target hosts"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}/engine/installer/kubespray
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  --ssh-extra-args='-o StrictHostKeyChecking=no' \
  -i ${ENGINE_CACHE}/repos/bifrost/playbooks/inventory/bifrost_inventory.py \
  playbooks/configure-targethosts.yml

# configure installer
echo "-------------------------------------------------------------------------"
echo "Info: Configure installer"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}/engine/installer/kubespray
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i localhost, \
  playbooks/configure-installer.yml

# install Kubernetes scenario
echo "-------------------------------------------------------------------------"
echo "Info: Install Kubernetes Scenario"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/kubespray
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  --ssh-extra-args='-o StrictHostKeyChecking=no' \
  --user root \
  -i inventory/engine/bifrost_inventory.py \
  cluster.yml

# run post-deployment tasks
echo "-------------------------------------------------------------------------"
echo "Info: Running post deployment tasks"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}/engine/installer/kubespray
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  --ssh-extra-args='-o StrictHostKeyChecking=no' \
  -i ${ENGINE_CACHE}/repos/kubespray/inventory/engine/bifrost_inventory.py \
  playbooks/post-deployment.yml

# vim: set ts=2 sw=2 expandtab:

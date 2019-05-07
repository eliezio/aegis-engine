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

# create libvirt resources if not baremetal, install and configure bifrost
echo "Info: Prepare nodes, configure bifrost and create bifrost inventory"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_PATH}
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i localhost, \
  -e baremetal=$BAREMETAL \
  ${BIFROST_ROOT_DIR}/playbooks/main.yml
echo "-------------------------------------------------------------------------"

# install bifrost and enroll & deploy nodes
echo "Info: Install bifrost"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/bifrost/playbooks
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i inventory/target \
  bifrost-install.yml
echo "-------------------------------------------------------------------------"

echo "Info: Enroll and deploy nodes using bifrost"
echo "-------------------------------------------------------------------------"
cd ${ENGINE_CACHE}/repos/bifrost/playbooks
ansible-playbook ${ENGINE_ANSIBLE_PARAMS} \
  -i inventory/bifrost_inventory.py \
  bifrost-enroll-deploy.yml
echo "-------------------------------------------------------------------------"

echo "Info: Nodes are provisioned using bifrost!"
echo "-------------------------------------------------------------------------"

# vim: set ts=2 sw=2 expandtab:

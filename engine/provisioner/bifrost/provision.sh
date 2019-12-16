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
export ANSIBLE_LIBRARY="$HOME/.ansible/plugins/modules:/usr/share/ansible/plugins/modules:${ENGINE_CACHE}/repos/bifrost/playbooks/library"

# TODO: ignoring SC2015 for the timebeing so we don't break things
# shellcheck disable=SC2015
# set the BAREMETAL variable
grep -o "vendor.*" "${ENGINE_CACHE}/config/pdf.yml" | grep -q libvirt && export BAREMETAL=false || export BAREMETAL=true

# create libvirt resources if not baremetal, install and configure bifrost
echo "Info: Prepare nodes, configure bifrost and create bifrost inventory"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
  -e baremetal="${BAREMETAL}" \
  "${PROVISIONER_ROOT_DIR}/playbooks/main.yml"
echo "-------------------------------------------------------------------------"

# Bifrost looks at environment variable VENV to see if it needs to use
# virtual environment.
# See: https://docs.openstack.org/bifrost/latest/install/virtualenv.html
export VENV="${ENGINE_VENV}"
# In bifrost inventory/target and inventory/localhost are defined as:
# 127.0.0.1 ansible_connection=local
# Hence ansible_python_interpreter needs to be set for localhost
# tasks to force ansible to use python from virtual environment.

# install bifrost and enroll & deploy nodes
echo "Info: Install bifrost"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/bifrost/playbooks"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
  -i inventory/target \
  -e ansible_python_interpreter="${ENGINE_VENV}/bin/python" \
  bifrost-install.yml
echo "-------------------------------------------------------------------------"

echo "Info: Enroll and deploy nodes using bifrost"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/bifrost/playbooks"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
  -i inventory/bifrost_inventory.py \
  -e ansible_python_interpreter="${ENGINE_VENV}/bin/python" \
  bifrost-enroll-deploy.yml
echo "-------------------------------------------------------------------------"

echo "Info: Generate Ansible inventory"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/bifrost/playbooks"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS}" \
  -i inventory/bifrost_inventory.py \
  --ssh-extra-args " -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
  "${PROVISIONER_ROOT_DIR}/playbooks/generate-inventory.yml"

echo "-------------------------------------------------------------------------"
echo "Info: Nodes are provisioned using bifrost!"
echo "-------------------------------------------------------------------------"

# vim: set ts=2 sw=2 expandtab:

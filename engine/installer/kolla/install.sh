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

INSTALLER_ROOT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles:${ENGINE_CACHE}/repos/bifrost/playbooks/roles"
export ANSIBLE_LIBRARY="$HOME/.ansible/plugins/modules:/usr/share/ansible/plugins/modules:${ENGINE_CACHE}/repos/bifrost/playbooks/library"

# configure target hosts
echo "-------------------------------------------------------------------------"
echo "Info: Configure target hosts"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  "${INSTALLER_ROOT_DIR}/playbooks/configure-targethosts.yml"

# configure kolla installer
echo "-------------------------------------------------------------------------"
echo "Info: Configure kolla installer"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  "${INSTALLER_ROOT_DIR}/playbooks/configure-installer.yml"

# TODO: we need to run scenario pre-deployment tasks here in order to configure
# bootstrap scenario
echo "-------------------------------------------------------------------------"
echo "Info: Execute scenario pre deployment tasks"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  "${INSTALLER_ROOT_DIR}/playbooks/pre-deployment.yml"

# kolla-ansible: bootstrap servers
echo "-------------------------------------------------------------------------"
echo "Info: Kolla-ansible bootstrap servers"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/kolla-ansible/tools"
./kolla-ansible \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  --configdir "${ENGINE_CACHE}/config" \
  --passwords "${ENGINE_CACHE}/config/passwords.yml" \
  -e "@${ENGINE_CACHE}/config/kolla-ansible-extra-vars.yml" \
  bootstrap-servers

# kolla-ansible: prechecks
echo "-------------------------------------------------------------------------"
echo "Info: Kolla-ansible prechecks"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/kolla-ansible/tools"
./kolla-ansible \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  --configdir "${ENGINE_CACHE}/config" \
  --passwords "${ENGINE_CACHE}/config/passwords.yml" \
  -e "@${ENGINE_CACHE}/config/kolla-ansible-extra-vars.yml" \
  prechecks

# kolla-ansible: deploy
echo "-------------------------------------------------------------------------"
echo "Info: Kolla-ansible deploy"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/kolla-ansible/tools"
./kolla-ansible \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  --configdir "${ENGINE_CACHE}/config" \
  --passwords "${ENGINE_CACHE}/config/passwords.yml" \
  -e "@${ENGINE_CACHE}/config/kolla-ansible-extra-vars.yml" \
  deploy

# kolla-ansible: post-deploy
echo "-------------------------------------------------------------------------"
echo "Info: Kolla-ansible post-deploy"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_CACHE}/repos/kolla-ansible/tools"
./kolla-ansible \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  --configdir "${ENGINE_CACHE}/config" \
  --passwords "${ENGINE_CACHE}/config/passwords.yml" \
  -e "@${ENGINE_CACHE}/config/kolla-ansible-extra-vars.yml" \
  post-deploy

# NOTE: shellcheck SC1090 is disabled since openrc file is put in place during runtime
# shellcheck disable=SC1090
# source admin-openrc.sh for running post-deployment tasks
source "${ENGINE_CACHE}/config/admin-openrc.sh"

# run post-deployment tasks
echo "-------------------------------------------------------------------------"
echo "Info: Execute scenario and common post deployment tasks"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
  -i "${ENGINE_CACHE}/config/inventory.ini" \
  "${INSTALLER_ROOT_DIR}/playbooks/post-deployment.yml"

# vim: set ts=2 sw=2 expandtab:

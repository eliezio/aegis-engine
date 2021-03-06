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

#-------------------------------------------------------------------------------
# This file contains few environment variables that are required for engine startup.
# Ideally there should be as few variables as possible in this file and all the variables
# should be put into either var/global.yml or var/versions.yml but at engine startup
# Ansible is not available and it is not that elegant to translate Ansible vars to
# environment variables without Ansible.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Set paths of key stuff
#-------------------------------------------------------------------------------
# location of nordix workspace
export ENGINE_WORKSPACE="${ENGINE_WORKSPACE:-/opt/engine}"

# location of ENGINE_VENV
export ENGINE_VENV="${ENGINE_WORKSPACE}/.venv"

# location of the cache where the various config files will be kept and repositories will be cloned
export ENGINE_CACHE="${ENGINE_WORKSPACE}/.cache"

# location of the apps in swconfig repo
export APPS_PATH="${ENGINE_CACHE}/repos/swconfig/apps"

# location of the scenario overrides if there is one
export SCENARIO_OVERRIDES="${ENGINE_CACHE}/repos/swconfig/scenarios/${DEPLOY_SCENARIO}/${INSTALLER_TYPE}/overrides"

# the Engine version to use
export ENGINE_VERSION="${ENGINE_VERSION:-master}"

# the Engine execution mode. Possible values are
#   - online-deployment
#   - offline-deployment
#   - packaging
export EXECUTION_MODE="${EXECUTION_MODE:-online-deployment}"

#-------------------------------------------------------------------------------
# Packaging and offline deployment parameters
#-------------------------------------------------------------------------------
# the Engine offline package folder
export OFFLINE_PKG_FOLDER="/tmp/offline-package"

# the Engine offline package folder
export OFFLINE_PKG_FILE="/tmp/offline-package.tgz"

# the Engine offline self extracting installer file
export OFFLINE_INSTALLER_FILE="/tmp/k8s-installer-ubuntu1804.bsx"

#-------------------------------------------------------------------------------
# Set the inventory for bifrost
#-------------------------------------------------------------------------------
export BIFROST_INVENTORY_SOURCE="${BIFROST_INVENTORY_SOURCE:-/tmp/baremetal.yml}"

#-------------------------------------------------------------------------------
# Other variables
#-------------------------------------------------------------------------------
# additional parameters to pass to Ansible
export ENGINE_ANSIBLE_PARAMS="${ENGINE_ANSIBLE_PARAMS:-""}"

# vim: set ts=2 sw=2 expandtab:

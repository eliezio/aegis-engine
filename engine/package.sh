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
# Source engine library
#-------------------------------------------------------------------------------
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
# Install Ansible
#-------------------------------------------------------------------------------
install_ansible

#-------------------------------------------------------------------------------
# Start packaging process
#-------------------------------------------------------------------------------
echo "Info  : Start packaging process"
echo "-------------------------------------------------------------------------"
cd "${ENGINE_PATH}"
ansible-playbook "${ENGINE_ANSIBLE_PARAMS[@]}" \
    -i "${ENGINE_PATH}/engine/inventory/localhost.ini" \
    engine/playbooks/package-dependencies.yaml
echo "-------------------------------------------------------------------------"

#-------------------------------------------------------------------------------
# Log total time it took to finish to console
#-------------------------------------------------------------------------------
log_elapsed_time

# vim: set ts=2 sw=2 expandtab:

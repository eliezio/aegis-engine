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

# Avoid double sourcing the file
[[ -n ${ENGINE_LIB_SOURCED:-} ]] && return 0 || export ENGINE_LIB_SOURCED=1

function usage() {
    echo "
Usage: $(basename ${0}) [-p <pdf>] [-i <idf>] [-s sdf]

    -h: This message
    -p: POD Descriptor File (PDF). (Default ${ENGINE_PATH}/engine/engine/pdf.yml)
    -i: Installer Descriptor File (IDF). (Default ${ENGINE_PATH}/engine/var/idf.yml)
    -s: Scenario Descriptor File (SDF). (Default ${ENGINE_PATH}/engine/var/sdf.yml)
    "
    exit 0
}

function parse_cmdline_opts() {
    PDF=${ENGINE_PATH}/engine/var/pdf.yml
    IDF=${ENGINE_PATH}/engine/var/idf.yml
    SDF=${ENGINE_PATH}/engine/var/sdf.yml

    while getopts ":hp:i:s:" o; do
        case "${o}" in
            p) PDF="${OPTARG}" ;;
            i) IDF="${OPTARG}" ;;
            s) SDF="${OPTARG}" ;;
            h) usage ;;
            *) echo "ERROR: Invalid option '-${OPTARG}'"; usage ;;
        esac
    done

    # Do all the exports
    export PDF=$(realpath ${PDF})
    export IDF=$(realpath ${IDF})
    export SDF=$(realpath ${SDF})
}

function check_prerequisites() {
    #-------------------------------------------------------------------------------
    # We shouldn't be running as root
    #-------------------------------------------------------------------------------
    if [[ $(whoami) == "root" ]]; then
        echo "WARNING: This script should not be run as root!"
        echo "Elevated privileges are acquired automatically when necessary"
        echo "Waiting 10s to give you a chance to stop the script (Ctrl-C)"
        for x in $(seq 10 -1 1); do echo -n "$x..."; sleep 1; done
    fi

    #-------------------------------------------------------------------------------
    # Check if SSH keypair exists
    #-------------------------------------------------------------------------------
    if [[ ! -f $HOME/.ssh/id_rsa ]]; then
        echo "ERROR: You must have SSH keypair in order to run this script!"
        exit 1
    fi
}

# vim: set ts=2 sw=2 expandtab:

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

#-------------------------------------------------------------------------------
# Print the help message which includes the usage, the expected parameters
# and their default values if they are not specified
#-------------------------------------------------------------------------------
function usage() {
    echo "
Usage: $(basename ${0}) [-d <installer type>] [-s <scenario>] [-b <scenario baseline file>] [-o <operating system>] [-p <pod descriptor file>] [-i <installer decriptor file>] [-v] [-c] [-h]

    -d: Installer type to use for deploying selected scenario. (Default kubespray)
    -s: Scenario which the SUT is deployed with. (Default k8-calico-nofeature)
    -b: URI to Scenario Baseline File. (SDF) (Default file://\$ENGINE_PATH/engine/var/sdf.yml)
    -p: URI to POD Descriptor File (PDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml)
    -i: URI to Installer Descriptor File (IDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml)
    -o: Operating System to provision nodes with and could either be ubuntu1804 or centos7. (Default ubuntu1804)
    -v: Increase verbosity and keep logs for troubleshooting. (Default false)
    -c: Wipeout leftovers before execution. (Default false)
    -h: This message.
    "
    exit 0
}

#-------------------------------------------------------------------------------
# Parse the arguments that are passed to the script
# If an argument is not specified, default values for those are set
#
# The priority order is
# - arguments: overrides the default values and values set as environment
#   values. highest prio.
# - env vars: overrides the default values but not the values set from command
#   line.
# - default values: only takes effect if the user doesn't specify the value
#   of an argument either as an env var or from command line. lowest prio.
#-------------------------------------------------------------------------------
function parse_cmdline_opts() {
    # set variables to the values set in env - otherwise, set them to defaults
    INSTALLER_TYPE=${INSTALLER_TYPE:-kubespray}
    DEPLOY_SCENARIO=${DEPLOY_SCENARIO:-k8-calico-nofeature}
    SDF=${SDF:-"file://${ENGINE_PATH}/engine/var/sdf.yml"}
    DISTRO=${DISTRO:-ubuntu1804}
    PDF=${PDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml"}
    IDF=${IDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml"}
    CLEANUP=${CLEANUP:-false}
    VERBOSITY=${VERBOSITY:-false}

    # get values passed as command line arguments, overriding the defaults or
    # the ones set by using env variables
    while getopts ":hd:s:b:o:p:i:cv" o; do
        case "${o}" in
            h) usage ;;
            d) INSTALLER_TYPE="${OPTARG}" ;;
            s) DEPLOY_SCENARIO="${OPTARG}" ;;
            b) SDF="${OPTARG}" ;;
            o) DISTRO="${OPTARG}" ;;
            p) PDF="${OPTARG}" ;;
            i) IDF="${OPTARG}" ;;
            c) CLEANUP="true" ;;
            v) VERBOSITY="true" ;;
            *) echo "ERROR: Invalid option '-${OPTARG}'"; usage ;;
        esac
    done

    # Do all the exports
    export INSTALLER_TYPE=${INSTALLER_TYPE}
    export DEPLOY_SCENARIO=${DEPLOY_SCENARIO}
    export SDF=${SDF}
    export DISTRO=${DISTRO}
    export PDF=${PDF}
    export IDF=${IDF}
    export CLEANUP=${CLEANUP}
    export VERBOSITY=${VERBOSITY}
}

#-------------------------------------------------------------------------------
# Check some prerequisites before proceeding further.
# Any other check that could be fatal for script to continue should be checked
# here so we quite as early as possible. Current checks are
# - the user shall not be root
# - the ssh keypair shall be created in advance
# - env_reset shall not be present
#-------------------------------------------------------------------------------
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
    # Check if SSH key exists
    #-------------------------------------------------------------------------------
    if [[ ! -f $HOME/.ssh/id_rsa ]]; then
        echo "ERROR: You must have SSH keypair in order to run this script!"
        exit 1
    fi

    #-------------------------------------------------------------------------------
    # We are using sudo so we need to make sure that env_reset is not present
    #-------------------------------------------------------------------------------
    sudo sed -i "s/^Defaults.*env_reset/#&/" /etc/sudoers
}

#-------------------------------------------------------------------------------
# Set few environment variables and source the other files that have additional
# environment variables set in them for further use
#-------------------------------------------------------------------------------
function bootstrap_environment() {
    # source engine-vars
    source $ENGINE_PATH/engine/config/engine-vars

    # Make sure we pass ENGINE_PATH everywhere
    export ENGINE_ANSIBLE_PARAMS+=" -e engine_path=${ENGINE_PATH}"

    # Make sure everybody knows where our global roles are
    export ANSIBLE_ROLES_PATH="$HOME/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles:${ENGINE_PATH}/engine/playbooks/roles"

    # Update path
    if [[ -z $(echo $PATH | grep "$HOME/.local/bin")  ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

#-------------------------------------------------------------------------------
# Remove leftovers of previous runs
# Leftovers of previous run might result in failures, especially within CI/CD
# so this function is important to use but it is not executed by default.
#-------------------------------------------------------------------------------
function cleanup() {
    # remove engine venv, cache and .ansible
    /bin/rm -rf $ENGINE_VENV $ENGINE_CACHE $HOME/.ansible

    # stop ironic-conductor service before dropping ironic database
    sudo systemctl stop ironic-conductor > /dev/null 2>&1 || true

    # remove ironic and inspector database
    if $(which mysql &> /dev/null); then
        sudo mysql --execute "drop database ironic;" > /dev/null 2>&1 || true
        sudo mysql --execute "drop database inspector;" > /dev/null 2>&1 || true
    fi

    # restart ironic services
    sudo systemctl restart ironic-api > /dev/null 2>&1 || true
    sudo systemctl restart ironic-conductor > /dev/null 2>&1 || true
    sudo systemctl restart ironic-inspector > /dev/null 2>&1 || true

    # clean and remove rabbitmq service
    sudo apt-get purge --auto-remove -y rabbitmq-server
}

#-------------------------------------------------------------------------------
# In order to install Ansible on the host, few packages need to be installed
# before that. This function determines the distro specific package names
# by mapping them to the package list, installs them and continues with
# Ansible and other Python package installations. The installation of Python
# packages are done in Virtualenv.
# In order to protect ourselves from issues that could come from upstream,
# OpenStack Upper Constraints is used so we install what is tested/verified.
#-------------------------------------------------------------------------------
function install_ansible() {
    set -eu

    local install_map

    declare -A PKG_MAP

    # workaround: for latest bindep to work, it needs to use en_US local
    export LANG="C"

    CHECK_CMD_PKGS=(
        gcc
        libffi
        libopenssl
        lsb-release
        make
        net-tools
        python-devel
        python
        python-pyyaml
        venv
        wget
        curl
    )

    source /etc/os-release || source /usr/lib/os-release
    case ${ID,,} in
        ubuntu|debian)
        OS_FAMILY="Debian"
        export DEBIAN_FRONTEND=noninteractive
        INSTALLER_CMD="sudo -H -E apt-get -y -q=3 install"
        CHECK_CMD="dpkg -l"
        PKG_MAP=(
            [gcc]=gcc
            [libffi]=libffi-dev
            [libopenssl]=libssl-dev
            [lsb-release]=lsb-release
            [make]=make
            [net-tools]=net-tools
            [pip]=python-pip
            [python]=python-minimal
            [python-devel]=libpython-dev
            [python-pyyaml]=python-yaml
            [venv]=python-virtualenv
            [wget]=wget
            [curl]=curl
        )
        EXTRA_PKG_DEPS=( apt-utils )
        sudo apt-get update
        ;;

        *) echo "ERROR: Supported package manager not found.  Supported: apt, dnf, yum, zypper"; exit 1;;
    esac

    # Build instllation map
    for pkgmap in ${CHECK_CMD_PKGS[@]}; do
        install_map+=(${PKG_MAP[$pkgmap]} )
    done

    install_map+=(${EXTRA_PKG_DEPS[@]} )

    ${INSTALLER_CMD} ${install_map[@]}

    # Note(cinerama): If pip is linked to pip3, the rest of the install
    # won't work. Remove the alternatives. This is due to ansible's
    # python 2.x requirement.
    if [[ $(readlink -f /etc/alternatives/pip) =~ "pip3" ]]; then
        sudo -H update-alternatives --remove pip $(readlink -f /etc/alternatives/pip)
    fi

    # We need to prepare our virtualenv now
    virtualenv --quiet --no-site-packages ${ENGINE_VENV}
    set +u
    source ${ENGINE_VENV}/bin/activate
    set -u

    # We are inside the virtualenv now so we should be good to use pip and python from it.
    # TODO: move $ENGINE_PIP_VERSION to $ENGINE_PATH/engine/var/versions.yml
    pip -q install --upgrade pip==$ENGINE_PIP_VERSION # We need a version which supports the '-c' parameter
    # TODO: move ansible-lint version to $ENGINE_PATH/engine/var/versions.yml
    pip -q install --upgrade ara virtualenv pip setuptools shade ansible==$ENGINE_ANSIBLE_VERSION ansible-lint==3.4.21

    ara_location=$(python -c "import os,ara; print(os.path.dirname(ara.__file__))")
    export ANSIBLE_CALLBACK_PLUGINS="/etc/ansible/roles/plugins/callback:${ara_location}/plugins/callbacks"
}

# vim: set ts=2 sw=2 expandtab:

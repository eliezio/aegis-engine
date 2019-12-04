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
Usage: $(basename ${0}) [-d <installer type>] [-r <provisioner type>] [-s <scenario>] [-b <scenario baseline file>] [-o <operating system>] [-p <pod descriptor file>] [-i <installer decriptor file>] [-e <heat environment file>] [-l \"<provision>,<installer>\"] [-v] [-c] [-h]

    -d: Installer type to use for deploying selected scenario. (Default kubespray)
    -r: Provisioner type to use for provisioning nodes. (Default bifrost)
    -s: Scenario which the SUT is deployed with. (Default k8-calico-nofeature)
    -b: URI to Scenario Baseline File. (SDF) (Default file://\$ENGINE_PATH/engine/var/sdf.yml)
    -p: URI to POD Descriptor File (PDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml)
    -i: URI to Installer Descriptor File (IDF). (Default https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml)
    -u: If provisioner is Heat, path to OpenStack openrc file. (No default)
    -e: URI to OpenStack Heat Environment File specific to cloud and scenario. (Default https://gerrit.nordix.org/gitweb?p=infra/engine.git;a=blob_plain;f=engine/provisioner/heat/playbooks/roles/install-configure-heat/files/heat-environment.yaml)
    -o: Operating System to provision nodes with. (Default ubuntu1804)
    -l: List of stages to run in a comma separated fashion. (Default execute all)
    -v: Increase verbosity and keep logs for troubleshooting. (Default false)
    -a: List of apps to be installed on top of the cloud (Default: none)
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
    PROVISIONER_TYPE=${PROVISIONER_TYPE:-bifrost}
    DEPLOY_SCENARIO=${DEPLOY_SCENARIO:-k8-calico-nofeature}
    SDF=${SDF:-"file://${ENGINE_PATH}/engine/var/sdf.yml"}
    DISTRO=${DISTRO:-ubuntu1804}
    PDF=${PDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-pdf.yml"}
    IDF=${IDF:-"https://gerrit.nordix.org/gitweb?p=infra/hwconfig.git;a=blob_plain;f=pods/nordix-vpod1-idf.yml"}
    HEAT_ENV_FILE=${HEAT_ENV_FILE:-"https://gerrit.nordix.org/gitweb?p=infra/engine.git;a=blob_plain;f=engine/provisioner/heat/playbooks/roles/install-configure-heat/files/heat-environment.yaml"}
    DO_PROVISION=${DO_PROVISION:-1}
    DO_INSTALLER=${DO_INSTALLER:-1}
    DEPLOY_STAGE_LIST=${DEPLOY_STAGE_LIST:-""}
    CLEANUP=${CLEANUP:-false}
    VERBOSITY=${VERBOSITY:-false}

    # get values passed as command line arguments, overriding the defaults or
    # the ones set by using env variables
    while getopts ":hd:r:s:b:o:p:i:e:u:l:a:cv" o; do
        case "${o}" in
            h) usage ;;
            d) INSTALLER_TYPE="${OPTARG}" ;;
            r) PROVISIONER_TYPE="${OPTARG}" ;;
            s) DEPLOY_SCENARIO="${OPTARG}" ;;
            b) SDF="${OPTARG}" ;;
            o) DISTRO="${OPTARG}" ;;
            p) PDF="${OPTARG}" ;;
            i) IDF="${OPTARG}" ;;
            e) HEAT_ENV_FILE="${OPTARG}" ;;
            u) OPENRC="${OPTARG}" ;;
            a) APPS="${OPTARG}" ;;
            c) CLEANUP="true" ;;
            v) VERBOSITY="true" ;;
            l) DEPLOY_STAGE_LIST="${OPTARG}" ;;
            *) echo "ERROR: Invalid option '-${OPTARG}'"; usage ;;
        esac
    done

    # if provisioner type is heat, we need openrc as well
    if [[ "$PROVISIONER_TYPE" == "heat" && -z "${OPENRC:-}" ]]; then
      echo "Error: You must provide path to openrc file in order to use Heat as provisioner!"
      exit 1
    fi

    # check if specified openrc exists
    if [[ "$PROVISIONER_TYPE" == "heat" && ! -f $OPENRC ]]; then
      echo "Error: Specified openrc file '$OPENRC' does not exist!"
      exit 1
    fi

    # check the stages enabled in DEPLOY_STAGE_LIST
    if [[ ! -z "$DEPLOY_STAGE_LIST" ]]; then
      DO_PROVISION=$(echo "$DEPLOY_STAGE_LIST" | grep -c provision || true)
      DO_INSTALLER=$(echo "$DEPLOY_STAGE_LIST" | grep -c installer || true)
    fi

    # Do all the exports
    export INSTALLER_TYPE=${INSTALLER_TYPE}
    export PROVISIONER_TYPE=${PROVISIONER_TYPE}
    export DEPLOY_SCENARIO=${DEPLOY_SCENARIO}
    export SDF=${SDF}
    export DISTRO=${DISTRO}
    export PDF=${PDF}
    export IDF=${IDF}
    export HEAT_ENV_FILE=${HEAT_ENV_FILE}
    export DO_PROVISION=${DO_PROVISION}
    export DO_INSTALLER=${DO_INSTALLER}
    export CLEANUP=${CLEANUP}
    export VERBOSITY=${VERBOSITY}

    # export APPS
    if [[ ! -z "${APPS:-}" ]]; then
      export APPS=${APPS}
    fi

    log_summary
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

    # Create engine workspace directory
    sudo mkdir -p ${ENGINE_WORKSPACE}
    sudo chown ${USER}:${USER} ${ENGINE_WORKSPACE}
}

#-------------------------------------------------------------------------------
# Remove leftovers of previous runs
# Leftovers of previous run might result in failures, especially within CI/CD
# so this function is important to use but it is not executed by default.
#-------------------------------------------------------------------------------
function cleanup() {
    # remove engine venv, cache and .ansible
    sudo /bin/rm -rf $ENGINE_VENV $ENGINE_CACHE $HOME/.ansible

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

    # in some cases, apt-get purge complains with "E: Unable to locate package rabbitmq-server"
    # and exits 100, causing this script and deploy.sh to fail.
    # run apt-get update to get rid of this
    sudo apt-get update -qq
    # clean and remove rabbitmq service
    sudo apt-get purge --auto-remove -y -qq rabbitmq-server > /dev/null
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
        pip
        python-pymysql
        python-zmq
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
            [python-devel]=libpython3-dev
            [python]=python3-minimal
            [pip]=python3-pip
            [python-pyyaml]=python3-yaml
            [python-pymysql]=python3-pymysql
            [python-zmq]=python3-zmq
            [venv]=virtualenv
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

    ${INSTALLER_CMD} ${install_map[@]} > /dev/null

    # We need to prepare our virtualenv now
    virtualenv -p python3 --quiet --no-site-packages ${ENGINE_VENV}
    set +u
    source ${ENGINE_VENV}/bin/activate
    set -u

    # We are inside the virtualenv now so we should be good to use pip and python from it.
    pip -q install --upgrade pip==$ENGINE_PIP_VERSION # We need a version which supports the '-c' parameter
    pip -q install --upgrade virtualenv pip setuptools shade ara==$ENGINE_ARA_VERSION \
        ansible==$ENGINE_ANSIBLE_VERSION ansible-lint==$ENGINE_ANSIBLE_LINT_VERSION

    ara_location=$(python -c "import os,ara; print(os.path.dirname(ara.__file__))")
    export ANSIBLE_CALLBACK_PLUGINS="/etc/ansible/roles/plugins/callback:${ara_location}/plugins/callbacks"

    if [[ "$OS_FAMILY" == "Debian" ]]; then
      # Get python3-apt and install into venv
      venv_site_packages_dir="${ENGINE_VENV}/lib/python3*/site-packages"
      cd /tmp
      echo "Downloading python3-apt using apt"
      apt download python3-apt

      echo "Extracting python3-apt..."
      dpkg -x python3-apt_*.deb python3-apt
      chown -R $USER:$USER /tmp/python3-apt/usr/lib/python3*/dist-packages

      echo "Moving python3-apt libraries into $venv_site_packages_dir"
      cp -r /tmp/python3-apt/usr/lib/python3*/dist-packages/* $venv_site_packages_dir
      cd $venv_site_packages_dir
      mv apt_pkg.*.so apt_pkg.so
      mv apt_inst.*.so apt_inst.so

      echo "Removing downloaded python3-apt in /tmp"
      rm -rf /tmp/python3-apt*
    fi
}

#-------------------------------------------------------------------------------
# Log summary & parameters to console
#-------------------------------------------------------------------------------
function log_summary() {
    echo
    echo "#---------------------------------------------------#"
    echo "#                   Environment                     #"
    echo "#---------------------------------------------------#"
    echo "User         : $USER"
    echo "Hostname     : $HOSTNAME"
    echo "Host OS      : $(source /etc/os-release &>/dev/null || source /usr/lib/os-release &>/dev/null; echo ${PRETTY_NAME})"
    echo "IP           : $(hostname -I | cut -d' ' -f1)"
    echo
    echo "#---------------------------------------------------#"
    echo "#                Deployment Started                 #"
    echo "#---------------------------------------------------#"
    echo "Date & Time  : $(date -u '+%F %T UTC')"
    echo "Scenario     : $DEPLOY_SCENARIO"
    echo "Target OS    : $DISTRO"
    echo "Installer    : $INSTALLER_TYPE"
    echo "Provisioner  : $PROVISIONER_TYPE"
    if [[ "$PROVISIONER_TYPE" == "heat" ]]; then
      echo "Openrc File  : $OPENRC"
      echo "Heat Env File: $HEAT_ENV_FILE"
    else
      echo "PDF          : $PDF"
      echo "IDF          : $IDF"
    fi
    echo "SDF          : $SDF"
    if [[ ! -z "${APPS:-}" ]]; then
      echo "Applications : $APPS"
    fi
    echo "Cleanup      : $CLEANUP"
    echo "Verbosity    : $VERBOSITY"
    echo "#---------------------------------------------------#"
    echo

}

#-------------------------------------------------------------------------------
# Log elapsed time to console
#-------------------------------------------------------------------------------
function log_elapsed_time() {
    elapsed_time=$SECONDS
    echo "#---------------------------------------------------#"
    echo "#                Deployment Completed               #"
    echo "#---------------------------------------------------#"
    echo "Date & Time  : $(date -u '+%F %T UTC')"
    echo "Elapsed      : $(($elapsed_time / 60)) minutes and $(($elapsed_time % 60)) seconds"
    echo "#---------------------------------------------------#"
}

# vim: set ts=2 sw=2 expandtab:

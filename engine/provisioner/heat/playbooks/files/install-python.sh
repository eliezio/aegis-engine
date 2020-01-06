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
set -o pipefail

# NOTE: due to stack creation issues on public cloud, installation of python
# and python-dev has been moved out of heat templates. The reason for this is
# that during initial boot of the instances, Ansible prerequisites python and
# python-dev are installed using boot script. Due to the reasons we can not
# explain and perhaps because of network issues on public cloud, apt fails,
# complaining about corruption - checksum mismatch. In turn, problematic
# instance(s) can not send completion signal at the end of boot phase, resulting
# in timeouts in stack creation thus complete failure of deployments.

source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
  ubuntu|debian)
    export DEBIAN_FRONTEND=noninteractive
    sudo -H -E apt update -q=3
    sudo -H -E apt install -y -q=3 python python-dev
    ;;
  rhel|fedora|centos)
    sudo yum install -y python python-devel
    ;;
  *)
    echo "ERROR: Supported package manager not found.  Supported: apt, dnf, yum, zypper"
    exit 1
    ;;
esac

# vim: set ts=2 sw=2 expandtab:

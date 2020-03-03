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

cat <<EOF
#---------------------------------------------------#
#             Self Extracting Installer             #
#---------------------------------------------------#
User            : $USER
Hostname        : $HOSTNAME
Host OS         : $(source /etc/os-release &> /dev/null || source /usr/lib/os-release &> /dev/null; echo "${PRETTY_NAME}")
IP              : $(hostname -I | cut -d' ' -f1)
#---------------------------------------------------#
Info  : Please wait while extracting dependencies.
        This might take a while.
#---------------------------------------------------#
EOF

ENGINE_WORKSPACE=/opt/engine
DESTINATION_FOLDER=/opt/engine/offline
export ENGINE_WORKSPACE DESTINATION_FOLDER

# NOTE (fdegir): we need to clean things up in order to prevent side effects from leftovers
sudo rm -rf "$DESTINATION_FOLDER" "$ENGINE_WORKSPACE/.cache" "$ENGINE_WORKSPACE/.venv"
sudo mkdir -p "$DESTINATION_FOLDER"
sudo chown -R "$USER":"$USER" "$ENGINE_WORKSPACE"

ARCHIVE=$(awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0")

tail -n+"$ARCHIVE" "$0" | tar -xz -C "$DESTINATION_FOLDER"

cd "$DESTINATION_FOLDER"
./install.sh

exit 0
__ARCHIVE_BELOW__

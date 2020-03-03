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

export OFFLINE_PKG_FOLDER="${OFFLINE_PKG_FOLDER:-/tmp/offline-package}"
export OFFLINE_PKG_FILE="${OFFLINE_PKG_FILE:-/tmp/offline-package.tgz}"

# TODO (fdegir): this is put here to allow testing of the functionality
# in an offline environment and will be removed once the changes are reviewed!
cd "$OFFLINE_PKG_FOLDER/git/engine"
git fetch "https://gerrit.nordix.org/infra/engine" refs/changes/67/3867/16 && git checkout FETCH_HEAD

# compress & archive offline dependencies
tar -C "$OFFLINE_PKG_FOLDER" -czf "$OFFLINE_PKG_FILE" .

# create self extracting installer
cat /tmp/decompress.sh "$OFFLINE_PKG_FILE" > "$OFFLINE_INSTALLER_FILE"
chmod +x "$OFFLINE_INSTALLER_FILE"

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

# NOTE (fdegir): In order to package and test the change for offline deployment,
# we need to include the change/patch within the package since that is what should
# be used during the deployment phase.
# check if we are running as part of CI verify job
GERRIT_CHANGE_ID="${GERRIT_CHANGE_ID:-}"
if [[ -n "${GERRIT_CHANGE_ID:-}" ]]; then
  # we need to get rid of infra/ from the project name to go to right folder in /tmp
  REPO_FOLDER_NAME="${GERRIT_PROJECT//*\//}"
  # repo git url to checkout from
  REPO_GIT_URL="https://gerrit.nordix.org/$GERRIT_PROJECT"
  echo "Info  : Running in CI so the change/patch will be packaged for testing."
  echo "        Checking out the change/patch $GERRIT_REFSPEC from $REPO_GIT_URL."
  # navigate to the folder and checkout the patch
  cd "$OFFLINE_PKG_FOLDER/git/$REPO_FOLDER_NAME"
  git fetch "$REPO_GIT_URL" "$GERRIT_REFSPEC" && git checkout FETCH_HEAD
fi

# compress & archive offline dependencies
tar -C "$OFFLINE_PKG_FOLDER" -czf "$OFFLINE_PKG_FILE" .

# create self extracting installer
cat /tmp/decompress.sh "$OFFLINE_PKG_FILE" > "$OFFLINE_INSTALLER_FILE"
chmod +x "$OFFLINE_INSTALLER_FILE"

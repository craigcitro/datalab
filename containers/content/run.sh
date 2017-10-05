#!/bin/bash -e

# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script supports a live mode in which a datalab git-clone directory is
# mapped to /devroot in this container. When /devroot exists, this script
# sets things up so that changes are immediately picked up by the noteboook
# server. For files in the static and templates directories, this means the
# developer can just modify the files in their datalab source tree and
# reload the web page to pick up the changes. For typescript
# files that get compiled into javascript, the developer needs to run the
# build script for those files, after which the changes will get noticed by
# the notebook server and it will automatically restart.

EXTERNAL_PORT=${EXTERNAL_PORT:-8081}
ERR_TMP_NOT_WRITABLE=2

check_tmp_directory() {
    echo "Verifying that the /tmp directory is writable"
    test_temp_file=$(mktemp --tmpdir=/tmp)
    if [ ! -e "${test_temp_file}" ]; then
	echo "Unable to write to the /tmp directory"
	exit "${ERR_TMP_NOT_WRITABLE}"
    fi
    rm "${test_temp_file}"
    echo "The /tmp directory is writable"
}

# Verify that we can write to the /tmp directory
check_tmp_directory

# Make sure the notebooks directory exists
mkdir -p /content/datalab/notebooks

# Create the notebook notary secret if one does not already exist
if [ ! -f /content/datalab/.config/notary_secret ]
then
  mkdir -p /content/datalab/.config
  openssl rand -base64 128 > /content/datalab/.config/notary_secret
fi

# Parse the settings overrides to get the (potentially overridden) value
# of the `datalabBasePath` setting.
EMPTY_BRACES="{}"
DATALAB_BASE_PATH=$(echo ${DATALAB_SETTINGS_OVERRIDES:-$EMPTY_BRACES} | python -c "import sys,json; print(json.load(sys.stdin).get('datalabBasePath',''))")

# Start the DataLab server
FOREVER_CMD="forever --minUptime 1000 --spinSleepTime 1000 -s"

if [ -d /devroot ]; then
  # For development purposes, if the user has mapped a /devroot dir, use it.
  echo "Running notebook server in live mode"
  # Use our internal node_modules dir
  export NODE_PATH="${NODE_PATH}:/datalab/web/node_modules"
  # Prevent (harmless) error message about missing .foreverignore
  IGNOREFILE=/devroot/build/web/nb/.foreverignore
  [ -f ${IGNOREFILE} ] || touch ${IGNOREFILE}
  # Auto-restart when the developer builds from the typescript files.
  echo ${FOREVER_CMD} --watch --watchDirectory /devroot/build/web/nb /devroot/build/web/nb/app.js
  ${FOREVER_CMD} --watch --watchDirectory /devroot/build/web/nb /devroot/build/web/nb/app.js
else
  echo "Open your browser to http://localhost:${EXTERNAL_PORT}/ to connect to Datalab."
  ${FOREVER_CMD} /datalab/web/app.js
fi

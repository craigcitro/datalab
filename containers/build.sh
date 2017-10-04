#!/bin/bash -e
# Copyright 2015 Google Inc. All rights reserved.
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

# Builds the Google Cloud DataLab docker image. Usage:
#   build.sh [path_of_pydatalab_dir]
# If [path_of_pydatalab_dir] is provided, it will copy the content of that dir into image.
# Otherwise, it will get the pydatalab by "git clone" from pydatalab repo.

pushd $(pwd) >> /dev/null
cd $(dirname "${BASH_SOURCE[0]}")
HERE=${PWD}

# Clean the build directory before building the image, so that the
# prepare.sh script rebuilds web sources
BUILD_DIR=../build
rm -rf $BUILD_DIR
../sources/build.sh

function install_rsync() {
  echo "Installing rsync"
  apt-get update -y -qq
  apt-get install -y -qq rsync
}

# Copy build outputs as a dependency of the Dockerfile
rsync -h >/dev/null 2>&1 || install_rsync
rsync -avp ../build/ build

# Copy the license file into the container
cp ../third_party/license.txt content/license.txt

# Build the docker image
docker build ${DOCKER_BUILD_ARGS} -t datalab .

popd >> /dev/null

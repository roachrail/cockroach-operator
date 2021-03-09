#!/usr/bin/env bash
# Copyright 2021 The Cockroach Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euxo pipefail

source "$(dirname "${0}")/teamcity-support.sh"


tc_start_block "Variable Setup"
# Matching the version name regex from within the cockroach code except
# for the `metadata` part at the end because Docker tags don't support
# `+` in the tag name.
# https://github.com/cockroachdb/cockroach/blob/4c6864b44b9044874488cfedee3a31e6b23a6790/pkg/util/version/version.go#L75
build_name="$(echo "${NAME}" | grep -E -o '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[-.0-9A-Za-z]+)?$')"
#                                         ^major           ^minor           ^patch         ^preRelease
version=$(echo ${build_name} | sed -e 's/^v//' | cut -d- -f 1)

if [[ -z "$build_name" ]] ; then
    echo "Invalid NAME \"${NAME}\". Must be of the format \"vMAJOR.MINOR.PATCH(-PRERELEASE)?\"."
    exit 1
fi

# TODO: switch to openshift repos
# TODO: implement dry run
docker_registry="docker.io/roachrail"
dst_docker_registry="docker.io/roachrail"
docker_image_repository="cockroachdb-operator"
dst_docker_image_repository="cockroachdb-operator-openshift"
bundle_docker_image_repository="cockroachdb-operator-openshift-bundle"
# TODO
rhel_registry=
tc_end_block "Variable Setup"


tc_start_block "Make and push docker images"
docker pull "$docker_registry/docker_image_repository:$build_name"
docker tag "$docker_registry/$docker_image_repository:$build_name" "$dst_docker_registry/$dst_docker_image_repository:$build_name"
# TODO: openshift credentials
configure_docker_creds
docker_login_with_redhat
docker push "$dst_docker_registry/$dst_docker_image_repository:$build_name"

make \
  RH_BUNDLE_IMAGE_REPOSITORY=$bundle_docker_image_repository \
  RH_BUNDLE_IMAGE_TAG=$build_name \
  RH_BUNDLE_REGISTRY=$docker_registry \
  RH_BUNDLE_VERSION=$build_name \
  release/bundle-image
tc_end_block "Make and push docker images"

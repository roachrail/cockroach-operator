#!/usr/bin/env bash

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

# TODO: implement dry run
docker_registry="docker.io/roachrail"
docker_image_repository="cockroachdb-operator"
git_repo_for_tag="roachrail/cockroachdb-operator"
tc_end_block "Variable Setup"


tc_start_block "Tag the release"
git tag "${build_name}"
tc_end_block "Tag the release"


tc_start_block "Make and push docker images"
configure_docker_creds
docker_login
make \
  DOCKER_REGISTRY="$docker_registry" \
  DOCKER_IMAGE_REPOSITORY="$docker_image_repository" \
  APP_VERSION="${build_name}" \
  release/image
tc_end_block "Make and push docker images"


# tc_start_block "Push release tag to GitHub"
# github_ssh_key="${GITHUB_COCKROACH_TEAMCITY_PRIVATE_SSH_KEY}"
# configure_git_ssh_key
# push_to_git "ssh://git@github.com/${git_repo_for_tag}.git" "$build_name"
# tc_end_block "Push release tag to GitHub"

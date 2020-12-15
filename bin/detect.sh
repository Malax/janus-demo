#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2034
app_dir="${1}"

# Can we modify cytokine to pass in the env dir as well?
# https://github.com/heroku/cytokine/blob/66e62f59874749168b183c0cd2fe2b58c0c72207/buildpack/buildpack.go#L111
#

heroku_buildpack_dir="$(
	cd "$(dirname "${0}")/.." || exit
	pwd
)"

# shellcheck source=lib/common.sh
source "${heroku_buildpack_dir}/lib/common.sh"

############################
# Run CNB lifecycle detector
############################

# lifecycle_dir is set by common.sh
# shellcheck disable=SC2154
"${lifecycle_dir}/detector" >&2

detect_name=$(from_toml "${heroku_buildpack_dir}/janus.toml" ".detect.name")
echo "${detect_name:-Janus}"

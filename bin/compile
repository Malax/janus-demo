#!/usr/bin/env bash
set -euo pipefail

app_dir="${1}"
cache_dir="${2}"
env_dir="${3}"

heroku_buildpack_dir="$(
	cd "$(dirname "${0}")/.." || exit
	pwd
)"

# shellcheck source=lib/common.sh
source "${heroku_buildpack_dir}/lib/common.sh"

# Initialize platform directory
mkdir "${CNB_PLATFORM_DIR}/env"
if compgen -G "${env_dir}/*" >/dev/null; then
	cp "${env_dir}"/* "${CNB_PLATFORM_DIR}/env/"
fi

# Initialize cache directories
JANUS_CACHE_LAYERS_DIR="${cache_dir}/.janus/layers"
mkdir -p "${JANUS_CACHE_LAYERS_DIR}"

# Restore cached layers from previous run
if compgen -G "${JANUS_CACHE_LAYERS_DIR}/*" >/dev/null; then
	mv "${JANUS_CACHE_LAYERS_DIR}"/* "${CNB_LAYERS_DIR}/"
fi

# Invoke CNB builder
##################################################################################
# - Will go through the buildpacks based on the previously calculated order
# - Create an isolated environment for each buildpack
#   - Handles the 'clear-env' setting in each buildpack's buildpack.toml
#   - Handles setting PATH, LD_LIBRARY_PATH, LIBRARY_PATH, CPATH and PKG_CONFIG_PATH for all previously executed
#     buildpacks.
# - Sets CNB_BUILDPACK_DIR for each buildpack execution

# lifecycle_dir is set by common.sh
# shellcheck disable=SC2154
if ! "${lifecycle_dir}/builder"; then
	echo "CNB builder failed, exiting early..."
	exit 1
fi

# Translate processes from the config layer to a Heroku Procfile
# TODO: <layers>/<layer>/env.launch/<process>/ support
JQ_PROCFILE_FILTER='.processes[] | (.type + ": " + .command)'
from_toml "${CNB_LAYERS_DIR}/config/metadata.toml" "${JQ_PROCFILE_FILTER}" >"${app_dir}/Procfile"

# Write layers to cache that are flagged for caching
JQ_BUILDPACKS_FILTER='[.buildpacks[].id  | gsub("/"; "_")] | join(" ")'
for buildpack in $(from_toml "${CNB_LAYERS_DIR}/config/metadata.toml" "${JQ_BUILDPACKS_FILTER}"); do
	for absolute_layer_toml_path in "${CNB_LAYERS_DIR}/${buildpack}/"*.toml; do
		if [[ ! -f "${absolute_layer_toml_path}" ]]; then
			continue
		fi

		layer_name="$(basename "${absolute_layer_toml_path}" ".toml")"
		absolute_layer_path="${absolute_layer_toml_path/%.toml/}"

		if [[ $(from_toml "${absolute_layer_toml_path}" '.cache') == "true" ]]; then
			mkdir -p "${JANUS_CACHE_LAYERS_DIR}/${buildpack}/${layer_name}"
			cp "${absolute_layer_toml_path}" "${JANUS_CACHE_LAYERS_DIR}/${buildpack}/${layer_name}.toml"
			cp -r "${absolute_layer_path}" "${JANUS_CACHE_LAYERS_DIR}/${buildpack}/"
		fi

		if [[ $(from_toml "${absolute_layer_toml_path}" '.launch') != "true" ]]; then
			rm "${absolute_layer_toml_path}"
			rm -rf "${absolute_layer_path}"
		fi
	done
done

##################################
# Generate Janus .profile.d script
##################################
from_toml "${CNB_GROUP_PATH}" '[.group[].id] | map(gsub("/"; "_")) | join(" ")' > "${app_dir}/.janus/buildpack_order"

mkdir -p "${app_dir}/.profile.d"
cp "${heroku_buildpack_dir}/opt/profile.d/"* "${app_dir}/profile.d/"

##############################
# Move .janus directory to app
##############################
mkdir -p "${app_dir}/.janus/"
mv /app/.janus/* "${app_dir}/.janus/"

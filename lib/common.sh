# Common code and configuration for both /bin/detect and /bin/compile

#################################
# Define helper functions
#################################
function from_toml() {
	local -r file="${1:?}"
	local -r filter="${2:?}"

	if [[ -f "${file}" ]]; then
		yj -t <"${file}" | jq -r "${filter}"
	else
		echo
	fi
}

#################################
# Setup CNB environment variables
#################################
export CNB_LOG_LEVEL="DEBUG"

# Note that this IS NOT the regular app directory, but the app directory of the codon worker which
# incidentially will be the same path during runtime of the customer's app. We make use of this to
# ensure layers paths do not change during build and runtime.
export CNB_LAYERS_DIR="/app/.janus/layers"

# This will be initialized in bin/compile since we have no access to environment variables in
# bin/detect. For better compatibilty with the CNB spec, we might want ot find a way around this.
export CNB_PLATFORM_DIR="${heroku_buildpack_dir:?}/cnb_platform"

export CNB_APP_DIR="${app_dir:?}"
export CNB_BUILDPACKS_DIR="${heroku_buildpack_dir:?}/buildpacks"
export CNB_ORDER_PATH="${heroku_buildpack_dir:?}/order.toml"
export CNB_GROUP_PATH="${CNB_LAYERS_DIR}/group.toml"
export CNB_PLAN_PATH="${CNB_LAYERS_DIR}/plan.toml"

#################################
# Miscellaneous setup
#################################
mkdir -p "${CNB_LAYERS_DIR}"
mkdir -p "${CNB_PLATFORM_DIR}"

# shellcheck disable=SC2154
# shellcheck disable=SC2034
lifecycle_dir="${heroku_buildpack_dir}/vendor/lifecycle-v0.9.3+linux.x86-64/lifecycle"

export PATH="${heroku_buildpack_dir:?}/vendor:${PATH}"

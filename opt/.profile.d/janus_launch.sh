#!/usr/bin/env bash
# Janus' script to implement launch requirements: https://github.com/buildpacks/spec/blob/main/buildpack.md#launch
# This script does not handle process specific tasks, those are implemented as wrapper scripts for those processes in
# the Procfile.

# Written during build, contains a space separated list of (escaped) buildpack ids in build order
escaped_buildpack_ids="$(cat /app/.janus/buildpack_order)"

# See: https://github.com/buildpacks/spec/blob/main/buildpack.md#environment-variable-modification-rules
function handle_env_dir() {
	local -r env_dir="${1:?}"

	for file in "${env_dir}"/*; do
		if [[ -f "${file}" && $file =~ ([^.]+)(\..*)? ]]; then
			local env_name="${BASH_REMATCH[1]}"
			local env_suffix="${BASH_REMATCH[2]}"

			case "${env_suffix}" in
			".delim") continue ;; # Skip .delim files, we only use them in .append and .prepend
			".override" | "") export "${env_name}"="$(cat "${file}")" ;;
			".default")
				if [[ -z "${!env_name}" ]]; then
					export "${env_name}"="$(cat "${file}")"
				fi
				;;
			".append")
				# shellcheck disable=SC2140
				export "${env_name}"="${!env_name}$(cat "${env_name}.delim" 2>/dev/null)$(cat "${file}")"
				;;
			".prepend")
				# shellcheck disable=SC2140
				export "${env_name}"="$(cat "${file}")$(cat "${env_name}.delim" 2>/dev/null)${!env_name}"
				;;
			*) ;;
			esac
		fi
	done
}

function handle_layer_dir() {
	local -r layer_dir="${1:?}"

	if [[ -d "${layer_dir}/bin" ]]; then
		export PATH="${layer_dir}/bin:${PATH}"
	fi

	if [[ -d "${layer_dir}/lib" ]]; then
		export LD_LIBRARY_PATH="${layer_dir}/lib:${LD_LIBRARY_PATH}"
	fi

	# NOTE: Order of env* directories matters!
	if [[ -d "${layer_dir}/env.launch" ]]; then
		handle_env_dir "${layer_dir}/env.launch"
	fi

	if [[ -d "${layer_dir}/env" ]]; then
		handle_env_dir "${layer_dir}/env"
	fi

	if [[ -d "${layer_dir}/profile.d" ]]; then
		for script in "${layer_dir}/profile.d"/*; do
			if [[ -f "${script}" ]]; then
				# shellcheck disable=SC1090
				source "${script}"
			fi
		done
	fi
}

for escaped_buildpack_id in ${escaped_buildpack_ids}; do
	# NOTE: Globs are replaced by bash with an alphabetically sorted list of matches. This matches the requirement
	# of the CNB spec to process layers in alphabetical ascending order.
	for layer_dir in "/app/.janus/layers/${escaped_buildpack_id}"/*; do
		if [[ -d "${layer_dir}" ]]; then
			handle_layer_dir "${layer_dir}"
		fi
	done
done

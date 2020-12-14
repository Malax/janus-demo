#!/usr/bin/env bash

escaped_buildpack_ids="$(cat /app/.janus/buildpack_order)"

# https://github.com/buildpacks/spec/blob/main/buildpack.md#environment-variable-modification-rules
function handle_env_dir() {
	local -r env_dir="${1:?}"

	for file in "${env_dir}"/*; do
		if [[ -f "${file}" && $file =~ ([^.]+)(\..*)? ]]; then
			local env_name="${BASH_REMATCH[1]}"
			local env_suffix="${BASH_REMATCH[2]}"

			case "${env_suffix}" in
			".append") ;;
			".default") ;;
			".delim") ;;
			".override") export "${env_name}"="$(cat "${file}")" ;;
			".prepend") ;;
			"") ;;
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

	if [[ -d "${layer_dir}/env" ]]; then
		handle_env_dir "${layer_dir}/env"
	fi

	if [[ -d "${layer_dir}/env.launch" ]]; then
		handle_env_dir "${layer_dir}/env.launch"
	fi
}

for escaped_buildpack_id in ${escaped_buildpack_ids}; do
	for layer_dir in "/app/.janus/layers/${escaped_buildpack_id}"/*; do
		if [[ -d "${layer_dir}" ]]; then
			handle_layer_dir "${layer_dir}"
		fi
	done
done

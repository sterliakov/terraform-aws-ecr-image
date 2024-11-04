#!/usr/bin/env bash
set -eu

##
# `docker pull` from repo with just curl
# https://distribution.github.io/distribution/spec/api/
#
# See ./pull_then_push.sh for example usage.
##

_dir_path() {
  # https://stackoverflow.com/a/43919044
  a="/$0"; a="${a%/*}"; a="${a:-.}"; a="${a##/}/"; BINDIR=$(cd "$a"; pwd)
  echo "$BINDIR"
}
DIR_PATH=$(_dir_path)

. "$DIR_PATH/helpers.sh"

check_vars REPO_URL IMAGE_TAG IMAGE_ARCH DOWNLOAD_DIR_PATH

_fetch_manifest() {
  echo '_fetch_manifest: starting' >&2

  curl_output=$(
    curl_with_auth_header -fsS \
    "$REPO_URL/manifests/$IMAGE_TAG"
  )
  manifests=$(jq -r '.manifests' <<<"$curl_output")
  config=$(jq -r '.config' <<<"$curl_output")
  if [ "$config" != "null" ]; then
    echo "Found correct manifest." >&2
    echo "$curl_output"
  elif [ "$manifests" != "null" ]; then
    echo "Got multiple architectures, choosing the appropriate one..." >&2
    image_hash=$(jq -r --arg arch "$IMAGE_ARCH" '.[] | select(.platform.architecture == $arch) | .digest' <<<"$manifests")
    if [ "$image_hash" = "null" ]; then
      available=$(jq -r '. | map(.platform.architecture) | join(", ")' <<<"$manifests")
      printf "Architecture %s not found. Available options are: %s\n" "$IMAGE_ARCH" "$available" >&2
      exit 2
    else
      IMAGE_TAG="$image_hash" _fetch_manifest
    fi
  else
    echo "Unknown manifest format: " >&2
    echo "$curl_output" >&2
    exit 1
  fi
  echo '_fetch_manifest: complete' >&2
}

_download_layer() {
  digest="${1:?No digest given as $1 to _download_layer}"
  file_path="${2:?No filepath given as $2 to _download_layer}"

  url="$REPO_URL/blobs/$digest"
  echo "_download_layer: starting downloading '$url' to '$file_path'" >&2

  curl_with_auth_header -fsS --output "$file_path" "$url"
  echo "_download_layer: complete downloading '$url' to '$file_path'" >&2
}

download_image() {
  dir_path="${1:?No destination given as $1 to download-image}"
  mkdir -p "$dir_path"
  rm -rf "$dir_path"/*.json

  manifest_file_path="$dir_path/manifest-pull.json"
  _fetch_manifest >"$manifest_file_path"

  config_digest=$(jq -r '.config.digest' <"$manifest_file_path")
  if [[ -z "$config_digest" || "$config_digest" == 'null' ]]; then
    echo 'download_image: failed to parse config_digest from manifest' >&2
    cat "$manifest_file_path" >&2
    return 1
  fi

  config_file_path="$dir_path/config.json"
  _download_layer "$config_digest" "$config_file_path"

  layers_dir_path="$dir_path/layers"
  mkdir -p "$layers_dir_path"
  rm -rf "$layers_dir_path"/*.blob

  jq -r '.layers | .[] | .digest' <"$manifest_file_path" | while read -r layer_digest ; do
    layer_file_path="$layers_dir_path/${layer_digest##*:}.blob"
    _download_layer "$layer_digest" "$layer_file_path"
  done

  echo "download_image: completed download to '$dir_path'" >&2
  echo "$manifest_file_path"
}

download_image "$DOWNLOAD_DIR_PATH"

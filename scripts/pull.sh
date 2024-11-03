#!/usr/bin/env bash
set -eu

##
# `docker pull` from repo with just curl
# https://distribution.github.io/distribution/spec/api/
#
# See ./pull_then_push.sh for example usage.
##

dir_path() {
  # https://stackoverflow.com/a/43919044
  a="/$0"; a="${a%/*}"; a="${a:-.}"; a="${a##/}/"; BINDIR=$(cd "$a"; pwd)
  echo "$BINDIR"
}

DIR_PATH=$(dir_path)

. "$DIR_PATH/helpers.sh"


check_vars REPO_FQDN REPO_NAME IMAGE_TAG DOWNLOAD_DIR_PATH

fetchManifest() {
  echo 'fetchManifest: starting' >&2

  check_vars REPO_URL IMAGE_TAG IMAGE_ARCH

  curl_output=$(
    curlWithAuthHeader -fsS \
    "$REPO_URL/manifests/$IMAGE_TAG" \
    2>/dev/null
  )
  manifests=$(jq -r '.manifests' <<<"$curl_output")
  config=$(jq -r '.config' <<<"$curl_output")
  if [ "$config" != "null" ]; then
    echo "Found correct manifest (config $config)" >&2
    echo "$curl_output"
  elif [ "$manifests" != "null" ]; then
    echo "Got multiple architectures, choosing the appropriate one..." >&2
    image_hash=$(jq -r --arg arch "$IMAGE_ARCH" '.[] | select(.platform.architecture == $arch) | .digest' <<<"$manifests")
    if [ "$image_hash" = "null" ]; then
      available=$(jq -r '. | map(.platform.architecture) | join(", ")' <<<"$manifests")
      printf "Architecture %s not found. Available options are: %s\n" "$IMAGE_ARCH" "$available" >&2
      exit 2
    else
      IMAGE_TAG="$image_hash" fetchManifest
    fi
  else
    echo "Unknown manifest format: " >&2
    echo "$curl_output" >&2
    exit 1
  fi
  echo 'fetchManifest: complete' >&2
}

downloadLayer() {
  digest="$1"
  file_path="$2"
  check_vars REPO_URL digest file_path

  url="$REPO_URL/blobs/$digest"
  echo "downloadLayer: starting downloading '$url' to '$file_path'" >&2

  curlWithAuthHeader -fsS \
    --output "$file_path" \
    "$url" \
    &>/dev/null
  echo "downloadLayer: complete downloading '$url' to '$file_path'" >&2
}

download_image() {
  dir_path="$1"
  check_vars dir_path
  mkdir -p "$dir_path"
  rm -rf "$dir_path"/*.json

  manifest_file_path="$dir_path/manifest-pull.json"
  fetchManifest >"$manifest_file_path"

  config_digest=$(jq -r '.config.digest' <"$manifest_file_path")
  if [[ -z "$config_digest" || "$config_digest" == 'null' ]]; then
    echo 'download_image: failed to parse config_digest from manifest' >&2
    cat "$manifest_file_path" >&2
    return 1
  fi

  config_file_path="$dir_path/config.json"
  downloadLayer "$config_digest" "$config_file_path"

  layers_dir_path="$dir_path/layers"
  mkdir -p "$layers_dir_path"
  rm -rf "$layers_dir_path"/*.blob

  jq -r '.layers | .[] | .digest' <"$manifest_file_path" | while read -r layer_digest ; do
    layer_file_path="$layers_dir_path/${layer_digest##*:}.blob"
    downloadLayer "$layer_digest" "$layer_file_path"
  done

  echo "download_image: completed download to '$dir_path'" >&2
  echo "$manifest_file_path"
}

REPO_URL=$(REPO_FQDN="$REPO_FQDN" REPO_NAME="$REPO_NAME" repoUrl)
download_image "$DOWNLOAD_DIR_PATH"

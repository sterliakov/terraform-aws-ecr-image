#!/usr/bin/env bash
set -eu

##
# `docker push` to repo with just curl
# https://distribution.github.io/distribution/spec/api/
# https://stackoverflow.com/a/59901770
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

check_vars REPO_URL IMAGE_TAG LAYER_PATHS CONFIG_PATH MANIFEST_PATH

echo "$LAYER_PATHS" | while read -r layer_path ; do
  if [[ ! -f "$layer_path" ]]; then
    echo "No file exists at layer_path of '$layer_path'" >&2
    exit 4
  fi
done

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "No file exists at CONFIG_PATH='$CONFIG_PATH'" >&2
  exit 4
fi


_file_size() {
  file_path="${1:?No file given to _file_size}"
  wc -c "$file_path" | cut -d ' ' -f 1
}

_file_digest() {
  file_path="${1:?No file given to _file_digest}"
  echo "sha256:$(sha256sum "$file_path" | cut -d ' ' -f 1)"
}

_initiate_upload() {
  echo '_initiate_upload: starting' >&2

  curl_output=$(
    curl_with_auth_header -X POST -siL -v \
    -H "Connection: close" \
    "$REPO_URL/blobs/uploads" \
    2>&1
  )
  assert_curl_status 202 "$curl_output"

  location=$(
    echo "$curl_output" \
    | grep Location \
    | sed '2q;d' \
    | cut -d: -f2- \
    | tr -d ' ' \
    | tr -d '\r'
  )
  if [[ -z "$location" ]]; then
    echo '_initiate_upload: Failed to parse Location from curl_output' >&2
    return 5
  fi

  echo '_initiate_upload: complete' >&2
  echo "$location"
}

_patch_layer() {
  echo '_patch_layer: starting' >&2

  curl_output=$(
    curl_with_auth_header -X PATCH -v \
    -H "Content-Type: application/octet-stream" \
    -H "Content-Length: ${file_size:?missing file_size}" \
    -H "Connection: close" \
    --data-binary @"${file_path:?missing file_path}" \
    "${target_location:?missing target_location}" \
    2>&1
  )
  assert_curl_status 201 "$curl_output"

  location=$(
    echo "$curl_output" \
    | grep 'Location' \
    | cut -d: -f2- \
    | tr -d ' ' \
    | tr -d '\r'
  )
  if [[ -z "$location" ]]; then
    echo '_patch_layer: Failed to parse location from curl_output' >&2
    return 5
  fi

  echo '_patch_layer: complete' >&2
  echo "$location"
}

_put_layer() {
  echo '_put_layer: starting' >&2

  curl_output=$(
    curl_with_auth_header -X PUT -v \
    -H "Content-Type: application/octet-stream" \
    -H "Content-Length: 0" \
    -H "Connection: close" \
    "${target_location:?missing target_location}?digest=${file_digest:?missing file_digest}" \
    2>&1
  )
  assert_curl_status 201 "$curl_output"

  echo '_put_layer: complete' >&2
}

_upload_manifest() {
  manifest_path="${1:?No manifest path given as $1 to _upload_manifest}"
  echo "_upload_manifest: starting '$manifest_path'" >&2

  size=$(( $(_file_size "$manifest_path") - 1 ))

  curl_output=$(
    curl_with_auth_header -X PUT -v \
    -H "Content-Type: application/vnd.docker.distribution.manifest.v2+json" \
    -H "Content-Length: $size" \
    -H "Connection: close" \
    -d "$(cat "$manifest_path")" \
    "$REPO_URL/manifests/$IMAGE_TAG" \
    2>&1
  )
  assert_curl_status 201 "$curl_output"

  echo "_upload_manifest: complete '$manifest_path'" >&2
}

upload_image() {
  echo "upload_image: starting config at '$CONFIG_PATH'" >&2
  config_size=$(_file_size "$CONFIG_PATH")
  config_digest=$(_file_digest "$CONFIG_PATH")
  patch_location=$(_initiate_upload)
  put_location=$(
    file_path="$CONFIG_PATH" \
    file_size="$config_size" \
    target_location="$patch_location" \
    _patch_layer
  )
  file_digest="$config_digest" target_location="$put_location" _put_layer
  echo "upload_image: complete config at '$CONFIG_PATH'" >&2

  echo 'upload_image: starting layers' >&2
  while read -r layer_path ; do
    echo "upload_image: starting layer at '$layer_path'" >&2
    layer_size=$(_file_size "$layer_path")
    layer_digest=$(_file_digest "$layer_path")
    patch_location=$(_initiate_upload)
    put_location=$(
      file_path="$layer_path" \
      file_size="$layer_size" \
      target_location="$patch_location" \
      _patch_layer
    )
    file_digest="$layer_digest" target_location="$put_location" _put_layer
    echo "upload_image: complete layer at '$layer_path'" >&2
  done <<< "$LAYER_PATHS"
  echo 'upload_image: complete layers' >&2

  _upload_manifest "${MANIFEST_PATH:?}"
  echo 'upload_image: complete manifest' >&2
}

upload_image

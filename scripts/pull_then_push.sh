#!/usr/bin/env bash
set -eu

##
# `docker pull` from a repo and then `docker push` to another repo with just curl
# https://distribution.github.io/distribution/spec/api/
#
# Example usage:
#   source './helpers.sh'
#   PULL_CURL_AUTH_HEADER=... \
#     PULL_REPO_FQDN='public.ecr.aws' \
#     PULL_REPO_NAME='lambda/provided' \
#     PULL_IMAGE_TAG='al2-x86_64' \
#     PULL_DOWNLOAD_DIR_PATH='/path/to/download/image/contents' \
#     PUSH_CURL_AUTH_HEADER=... \
#     PUSH_REPO_FQDN='123456789012.dkr.ecr.us-east-1.amazonaws.com' \
#     PUSH_REPO_NAME='my-repo' \
#     PUSH_IMAGE_TAG='latest' \
#     ./pull_then_push.sh
#
# Exit codes:
# * 1 - Undefined input variable
# * 2 - Missing tools
# * 3 - Pull failures
# * 4, 5 - Push failures
# * Other codes - curl failures or unexpected error
#
##

_dir_path() {
  # https://stackoverflow.com/a/43919044
  a="/$0"; a="${a%/*}"; a="${a:-.}"; a="${a##/}/"; BINDIR=$(cd "$a"; pwd)
  echo "$BINDIR"
}
DIR_PATH=$(_dir_path)

. "$DIR_PATH/helpers.sh"

check_vars PULL_REPO_FQDN PULL_REPO_NAME PULL_IMAGE_TAG PULL_IMAGE_ARCH
if [ -z ${PULL_CURL_AUTH_HEADER+x} ]; then
  echo >&2 "\$PULL_CURL_AUTH_HEADER is undefined. If no auth header required then set PULL_CURL_AUTH_HEADER=''"
  exit 1
fi
check_vars PULL_DOWNLOAD_DIR_PATH
check_vars PUSH_REPO_FQDN PUSH_REPO_NAME PUSH_IMAGE_TAG
if [ -z ${PUSH_CURL_AUTH_HEADER+x} ]; then
  echo >&2 "\$PUSH_CURL_AUTH_HEADER is undefined. If no auth header required then set PULL_CURL_AUTH_HEADER=''"
  exit 1
fi

# Check tools
if ! command -v curl &>/dev/null; then
  echo "curl not found" >&2
  exit 2
fi
if ! command -v jq &>/dev/null; then
  echo "jq not found, trying to install..." >&2
  bin_dir="$PULL_DOWNLOAD_DIR_PATH/bin"
  mkdir -p "$bin_dir"
  bin_dir=$(readlink -f "$bin_dir")
  if install_jq "$bin_dir"; then
    export PATH="$bin_dir:$PATH"
    echo "Installed $(jq --version)." >&2
  else
    echo "jq not found and could not be installed" >&2
    exit 2
  fi
fi

# Pull image
export CURL_AUTH_HEADER="$PULL_CURL_AUTH_HEADER"
manifest_path=$(
  REPO_URL=$(repo_url "$PULL_REPO_FQDN" "$PULL_REPO_NAME") \
  IMAGE_TAG="$PULL_IMAGE_TAG" \
  IMAGE_ARCH="$PULL_IMAGE_ARCH" \
  DOWNLOAD_DIR_PATH="$PULL_DOWNLOAD_DIR_PATH" \
  "$DIR_PATH/pull.sh"
)

# Push image
export CURL_AUTH_HEADER="$PUSH_CURL_AUTH_HEADER"
REPO_URL=$(repo_url "$PUSH_REPO_FQDN" "$PUSH_REPO_NAME") \
IMAGE_TAG="$PUSH_IMAGE_TAG" \
LAYER_PATHS=$(find "$PULL_DOWNLOAD_DIR_PATH/layers" -type f) \
CONFIG_PATH="$PULL_DOWNLOAD_DIR_PATH/config.json" \
MANIFEST_PATH="$manifest_path" \
  "$DIR_PATH/push.sh"

# Clean up
unset CURL_AUTH_HEADER
rm -rf "$PULL_DOWNLOAD_DIR_PATH"

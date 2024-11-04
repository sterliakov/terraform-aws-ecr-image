#! /usr/bin/env bash

curl_with_auth_header() {
  auth_params=()
  if [ -n "$CURL_AUTH_HEADER" ]; then
    auth_params+=('-H' "Authorization: $CURL_AUTH_HEADER")
  fi
  curl "${auth_params[@]}" -L "$@"
}

_curl_status() {
  curl_output="${1:?No curl output passed to _curl_status}"
  echo "$curl_output" | grep '^< HTTP/[0-9\.]* ' | tail -n 1 | awk '{print $3}'
}

assert_curl_status() {
  expected_code="$1"
  curl_output="$2"
  status_code=$(_curl_status "$curl_output")
  if [[ "$status_code" != "$expected_code" ]]; then
    echo "curl returned http status code of '$status_code' instead of '$expected_code'" >&2
    echo "$curl_output" >&2
    return 1
  fi
}

repo_url() {
  fqdn=${1:?No FQDN given at $1}
  name=${2:?No name given at $2}
  echo "https://$fqdn/v2/$name"
}

check_vars() {
  var_names=("$@")
  for var_name in "${var_names[@]}"; do
    if [ -z "${!var_name}" ]; then
      echo >&2 "$var_name is unset."
      var_unset="true"
    fi
  done
  if [ -n "${var_unset:-}" ]; then
    exit 1
  fi
  return 0
}

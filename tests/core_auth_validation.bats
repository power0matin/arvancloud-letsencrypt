#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/../core.sh"
  eval "$(sed -n '/^cleanup_auth_config() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^arvan_auth_header() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^verify_arvan_access() {/,/^}$/p' "$source_file")"

  export TEST_AUTH_DIR="${BATS_TEST_TMPDIR}/auth-temp"
  export MOCK_LOG="${BATS_TEST_TMPDIR}/auth.log"
  mkdir -p "$TEST_AUTH_DIR"
  : > "$MOCK_LOG"

  DOMAIN="example.com"
  ARVAN_ACCESS_KEY="test-only-token"
  ARVAN_API_URL="https://api.example.invalid/cdn/4.0/domains"
  AUTH_CONFIG_FILE=""
  MOCK_STATUS=200
  MOCK_BODY='{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":1}}'
  MOCK_CURL_STATUS=0
  MOCK_PAGINATION=0

  mktemp() {
    local template="$1" path
    [[ "$template" == /run/.arvancloud-letsencrypt-auth.XXXXXX ]] || return 1
    path="${TEST_AUTH_DIR}/auth-header.conf"
    : > "$path"
    printf '%s' "$path"
  }

  chmod_real() { command chmod "$@"; }
  chmod() { chmod_real "$@"; }

  curl() {
    local config_path="" previous="" arg url="" page=1
    while (($#)); do
      arg="$1"
      if [[ "$previous" == "--config" ]]; then config_path="$arg"; fi
      [[ "$arg" == https://* ]] && url="$arg"
      previous="$arg"
      shift
    done
    [[ "$url" == *"?page=2&per_page=100"* ]] && page=2
    printf 'url=%s\n' "$url" >> "$MOCK_LOG"
    if [[ -n "$config_path" && -f "$config_path" ]]; then
      printf 'mode=%s\n' "$(stat -c '%a' "$config_path")" >> "$MOCK_LOG"
      cat "$config_path" >> "$MOCK_LOG"
    fi

    [[ "$MOCK_CURL_STATUS" -eq 0 ]] || return "$MOCK_CURL_STATUS"
    if [[ "$MOCK_PAGINATION" == "1" && "$page" == "2" ]]; then
      printf '%s\n200' '{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":2}}'
    else
      printf '%s\n%s' "$MOCK_BODY" "$MOCK_STATUS"
    fi
  }

  log() { printf 'LOG\t%s\n' "$*" >> "$MOCK_LOG"; }
}

capture_status() {
  if "$@"; then
    COMMAND_STATUS=0
  else
    COMMAND_STATUS="$?"
  fi
}

assert_auth_file_removed() {
  [ ! -e "${TEST_AUTH_DIR}/auth-header.conf" ]
  [ -z "$AUTH_CONFIG_FILE" ]
}

@test "valid API response verifies access and removes the temporary auth file" {
  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 0 ]
  grep -Fq 'Authorization: Apikey test-only-token' "$MOCK_LOG"
  grep -Fq 'header = "Accept: application/json"' "$MOCK_LOG"
  grep -Fq $'LOG\tArvanCloud API access verified for example.com.' "$MOCK_LOG"
  grep -Fq 'mode=600' "$MOCK_LOG"
  assert_auth_file_removed
}

@test "HTTP 401 maps to credential failure and removes the temporary auth file" {
  MOCK_STATUS=401
  MOCK_BODY='{"message":"unauthorized"}'

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 10 ]
  assert_auth_file_removed
}

@test "HTTP 403 maps to credential or permission failure and removes the temporary auth file" {
  MOCK_STATUS=403
  MOCK_BODY='{"message":"forbidden"}'

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 10 ]
  assert_auth_file_removed
}

@test "reachable API without the requested zone returns the dedicated status" {
  MOCK_BODY='{"data":[{"id":"another-zone","domain":"other.example"}],"meta":{"last_page":1}}'

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 11 ]
  grep -Fq 'key can reach the API but cannot see the requested DNS zone' "$MOCK_LOG"
  assert_auth_file_removed
}

@test "zone access discovery follows pagination" {
  MOCK_BODY='{"data":[],"meta":{"last_page":2}}'
  MOCK_PAGINATION=1

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(grep -Fc '?page=1&per_page=100' "$MOCK_LOG")" -eq 1 ]
  [ "$(grep -Fc '?page=2&per_page=100' "$MOCK_LOG")" -eq 1 ]
  assert_auth_file_removed
}

@test "malformed domain response fails closed and cleans the auth file" {
  MOCK_BODY='{"items":[]}'

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 20 ]
  assert_auth_file_removed
}

@test "HTTP 5xx failure cleans the temporary auth file" {
  MOCK_STATUS=503
  MOCK_BODY='{"message":"temporary failure"}'

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 20 ]
  assert_auth_file_removed
}

@test "transport failure cleans the temporary auth file" {
  MOCK_CURL_STATUS=7

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 20 ]
  assert_auth_file_removed
}

@test "cleanup is safe to call more than once" {
  AUTH_CONFIG_FILE="${TEST_AUTH_DIR}/manual.conf"
  printf 'mock secret\n' > "$AUTH_CONFIG_FILE"

  cleanup_auth_config
  cleanup_auth_config

  [ ! -e "${TEST_AUTH_DIR}/manual.conf" ]
  [ -z "$AUTH_CONFIG_FILE" ]
}

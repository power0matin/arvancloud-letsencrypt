#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

setup() {
  local source_file="${BATS_TEST_DIRNAME}/../core.sh"
  eval "$(sed -n '/^cleanup_auth_config() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^arvan_auth_header() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^verify_arvan_access() {/,/^}$/p' "$source_file")"

  export TEST_AUTH_DIR="${BATS_TEST_TMPDIR}/auth-temp"
  mkdir -p "$TEST_AUTH_DIR"
  export MOCK_LOG="${BATS_TEST_TMPDIR}/auth.log"
  : > "$MOCK_LOG"

  DOMAIN="example.com"
  ARVAN_ACCESS_KEY="test-only-token"
  ARVAN_API_URL="https://api.example.invalid/cdn/4.0/domains"
  AUTH_CONFIG_FILE=""
  MOCK_STATUS=200
  MOCK_BODY='{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":1}}'
  MOCK_CURL_STATUS=0

  mktemp() {
    local template="$1"
    [[ "$template" == /run/.arvancloud-letsencrypt-auth.XXXXXX ]] || return 1
    local path="${TEST_AUTH_DIR}/auth-header.conf"
    : > "$path"
    printf '%s' "$path"
  }

  curl() {
    local config_path="" previous="" arg
    while (($#)); do
      arg="$1"
      if [[ "$previous" == "--config" ]]; then config_path="$arg"; fi
      previous="$arg"
      shift
    done
    printf 'config=%s\n' "$config_path" >> "$MOCK_LOG"
    if [[ -n "$config_path" && -f "$config_path" ]]; then
      stat -c '%a' "$config_path" >> "$MOCK_LOG"
      cat "$config_path" >> "$MOCK_LOG"
    fi
    [[ "$MOCK_CURL_STATUS" -eq 0 ]] || return "$MOCK_CURL_STATUS"
    printf '%s\n%s' "$MOCK_BODY" "$MOCK_STATUS"
  }

  chmod_real() { command chmod "$@"; }
  chmod() { chmod_real "$@"; }
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
  grep -Fq 
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
  local calls_file="${TEST_AUTH_DIR}/calls"
  curl() {
    local page=1 previous="" arg
    while (($#)); do
      if [[ "$previous" == "--config" ]]; then :; fi
      previous="$1"
      if [[ "$1" == *"?page=2&per_page=100"* ]]; then page=2; fi
      shift
    done
    printf '%s\n' "$page" >> "$calls_file"
    if [[ "$page" == "2" ]]; then
      printf '{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":2}}\n200'
    else
      printf '%s\n200' "$MOCK_BODY"
    fi
  }

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(wc -l < "$calls_file")" -eq 2 ]
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
LOG\tArvanCloud API access verified for example.com.' "$MOCK_LOG"
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
  local calls_file="${TEST_AUTH_DIR}/calls"
  curl() {
    local page=1 previous="" arg
    while (($#)); do
      if [[ "$previous" == "--config" ]]; then :; fi
      previous="$1"
      if [[ "$1" == *"?page=2&per_page=100"* ]]; then page=2; fi
      shift
    done
    printf '%s\n' "$page" >> "$calls_file"
    if [[ "$page" == "2" ]]; then
      printf '{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":2}}\n200'
    else
      printf '%s\n200' "$MOCK_BODY"
    fi
  }

  capture_status verify_arvan_access

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(wc -l < "$calls_file")" -eq 2 ]
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

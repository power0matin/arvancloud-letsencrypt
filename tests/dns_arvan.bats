#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  source "${BATS_TEST_DIRNAME}/../src/dns_arvan.sh"

  export MOCK_LOG="${BATS_TEST_TMPDIR}/mock-api.log"
  : > "$MOCK_LOG"
  HTTP_HEADER="${BATS_TEST_TMPDIR}/http-header"
  : > "$HTTP_HEADER"
  MOCK_GET_HTTP_CODE=200
  MOCK_FIRST_GET_HTTP_CODE=""

  Arvan_Token="mock-api-key"
  STORED_TOKEN=""
  SAVED_CONFIG_NAME=""
  SAVED_CONFIG_VALUE=""
  COMMAND_STATUS=0

  MOCK_GET_RC=0
  MOCK_POST_RC=0
  MOCK_DELETE_RC=0

  MOCK_DOMAIN_PAGE1='{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":1}}'
  MOCK_DOMAIN_PAGE2='{"data":[],"meta":{"last_page":2}}'
  MOCK_RECORD_PAGE1='{"data":[],"meta":{"last_page":1}}'
  MOCK_RECORD_PAGE2='{"data":[],"meta":{"last_page":2}}'
  MOCK_POST_RESPONSE='{"data":{"value":{"text":"challenge-value"}}}'
  MOCK_DELETE_RESPONSE='{"success":true}'

  _info() { :; }
  _err() { :; }
  _readaccountconf_mutable() { printf '%s' "$STORED_TOKEN"; }
  _saveaccountconf_mutable() {
    SAVED_CONFIG_NAME="$1"
    SAVED_CONFIG_VALUE="$2"
  }
  _contains() {
    case "$1" in
      *"$2"*) return 0 ;;
      *) return 1 ;;
    esac
  }
  _math() { printf '%s\n' "$(( $1 $2 $3 ))"; }
  _sleep() { printf 'SLEEP\t%s\n' "$1" >> "$MOCK_LOG"; }

  _get() {
    local url="$1" body request_count http_code
    printf 'GET\t%s\n' "$url" >> "$MOCK_LOG"
    request_count="$(awk -F '\t' '$1 == "GET" { count++ } END { print count + 0 }' "$MOCK_LOG")"
    http_code="$MOCK_GET_HTTP_CODE"
    if [ "$request_count" -eq 1 ] && [ -n "$MOCK_FIRST_GET_HTTP_CODE" ]; then
      http_code="$MOCK_FIRST_GET_HTTP_CODE"
    fi
    printf 'HTTP/2 %s Mock\r\n' "$http_code" > "$HTTP_HEADER"
    case "$url" in
      *"/dns-records?page=1&per_page=100"*) body="$MOCK_RECORD_PAGE1" ;;
      *"/dns-records?page=2&per_page=100"*) body="$MOCK_RECORD_PAGE2" ;;
      *"/domains/?page=1&per_page=100"*) body="$MOCK_DOMAIN_PAGE1" ;;
      *"/domains/?page=2&per_page=100"*) body="$MOCK_DOMAIN_PAGE2" ;;
      *)
        printf 'Unexpected GET URL: %s\n' "$url" >&2
        return 1
        ;;
    esac
    printf '%s' "$body"
    return "$MOCK_GET_RC"
  }

  _post() {
    local data="$1" url="$2" method="$4" body
    printf 'POST\t%s\t%s\t%s\n' "$method" "$url" "$data" >> "$MOCK_LOG"
    case "$method" in
      POST)
        body="$MOCK_POST_RESPONSE"
        printf '%s' "$body"
        return "$MOCK_POST_RC"
        ;;
      DELETE)
        body="$MOCK_DELETE_RESPONSE"
        printf '%s' "$body"
        return "$MOCK_DELETE_RC"
        ;;
      *)
        printf 'Unexpected POST method: %s\n' "$method" >&2
        return 1
        ;;
    esac
  }
}

capture_status() {
  if "$@"; then
    COMMAND_STATUS=0
  else
    COMMAND_STATUS="$?"
  fi
}

post_count() {
  awk -F '\t' '$1 == "POST" { count++ } END { print count + 0 }' "$MOCK_LOG"
}

sleep_count() {
  awk -F '\t' '$1 == "SLEEP" { count++ } END { print count + 0 }' "$MOCK_LOG"
}

@test "add saves the DNS token and creates a TXT challenge for the resolved zone" {
  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$SAVED_CONFIG_NAME" = "Arvan_Token" ]
  [ "$SAVED_CONFIG_VALUE" = "mock-api-key" ]
  [ "$(post_count)" -eq 1 ]

  target="${ARVAN_API_URL}/example.com/dns-records"
  awk -F '\t' -v target="$target" '$1 == "POST" && $2 == "POST" && $3 == target { found=1 } END { exit !found }' "$MOCK_LOG"
  grep -Fq '"name":"_acme-challenge"' "$MOCK_LOG"
  grep -Fq '"text":"challenge-value"' "$MOCK_LOG"
}

@test "add treats an already-existing duplicate TXT record as success" {
  MOCK_POST_RESPONSE='{"message":"Record Data is duplicate"}'

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(post_count)" -eq 1 ]
}

@test "add fails when the API response does not confirm the requested TXT value" {
  MOCK_POST_RESPONSE='{"message":"validation failed"}'

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(post_count)" -eq 1 ]
}

@test "zone discovery paginates and can find the domain on page two" {
  MOCK_DOMAIN_PAGE1='{"data":[],"meta":{"last_page":2}}'
  MOCK_DOMAIN_PAGE2='{"data":[{"id":"zone-id","domain":"example.com"}],"meta":{"last_page":2}}'

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(grep -Fc '/domains/?page=' "$MOCK_LOG")" -eq 2 ]
  [ "$(post_count)" -eq 1 ]
}

@test "remove deletes only the exact TXT name and value, including on a later page" {
  MOCK_RECORD_PAGE1='{"data":[{"id":"wrong-name","type":"TXT","name":"other","value":{"text":"wanted-value"}},{"id":"wrong-value","type":"TXT","name":"_acme-challenge","value":{"text":"different-value"}}],"meta":{"last_page":2}}'
  MOCK_RECORD_PAGE2='{"data":[{"id":"wrong-type","type":"A","name":"_acme-challenge","value":{"text":"wanted-value"}},{"id":"exact-record","type":"TXT","name":"_acme-challenge","value":{"text":"wanted-value"}}],"meta":{"last_page":2}}'

  capture_status dns_arvan_rm "_acme-challenge.example.com" "wanted-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(grep -Fc '/dns-records?page=' "$MOCK_LOG")" -eq 2 ]
  [ "$(post_count)" -eq 1 ]
  target="${ARVAN_API_URL}/example.com/dns-records/exact-record"
  awk -F '\t' -v target="$target" '$1 == "POST" && $2 == "DELETE" && $3 == target { found=1 } END { exit !found }' "$MOCK_LOG"
}

@test "remove leaves unrelated TXT records untouched when the exact value is absent" {
  MOCK_RECORD_PAGE1='{"data":[{"id":"other-record","type":"TXT","name":"_acme-challenge","value":{"text":"not-the-requested-value"}}],"meta":{"last_page":1}}'

  capture_status dns_arvan_rm "_acme-challenge.example.com" "wanted-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(post_count)" -eq 0 ]
}

@test "remove reports failure when deleting the exact TXT record fails" {
  MOCK_RECORD_PAGE1='{"data":[{"id":"exact-record","type":"TXT","name":"_acme-challenge","value":{"text":"wanted-value"}}],"meta":{"last_page":1}}'
  MOCK_DELETE_RC=1

  capture_status dns_arvan_rm "_acme-challenge.example.com" "wanted-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(post_count)" -eq 1 ]
}

@test "a transient 503 response is retried and a later successful GET proceeds" {
  MOCK_FIRST_GET_HTTP_CODE=503

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$(grep -Fc '/domains/?page=1&per_page=100' "$MOCK_LOG")" -eq 2 ]
  [ "$(sleep_count)" -eq 1 ]
  [ "$(post_count)" -eq 1 ]
}

@test "persistent 503 responses stop after three attempts" {
  MOCK_GET_HTTP_CODE=503

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(grep -Fc '/domains/?page=1&per_page=100' "$MOCK_LOG")" -eq 3 ]
  [ "$(sleep_count)" -eq 2 ]
  [ "$(post_count)" -eq 0 ]
}

@test "authorization failures are not retried" {
  MOCK_GET_HTTP_CODE=401
  MOCK_DOMAIN_PAGE1='{"message":"unauthorized"}'

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(grep -Fc '/domains/?page=1&per_page=100' "$MOCK_LOG")" -eq 1 ]
  [ "$(sleep_count)" -eq 0 ]
  [ "$(post_count)" -eq 0 ]
}

@test "a failed transport request is retried a bounded number of times" {
  MOCK_GET_RC=7

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(grep -Fc '/domains/?page=1&per_page=100' "$MOCK_LOG")" -eq 3 ]
  [ "$(sleep_count)" -eq 2 ]
  [ "$(post_count)" -eq 0 ]
}

@test "malformed zone data fails closed" {
  MOCK_DOMAIN_PAGE1='{"items":[]}'

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ "$(post_count)" -eq 0 ]
}

@test "missing DNS credentials fail before any API request" {
  Arvan_Token=""
  STORED_TOKEN=""

  capture_status dns_arvan_add "_acme-challenge.example.com" "challenge-value"

  [ "$COMMAND_STATUS" -eq 1 ]
  [ ! -s "$MOCK_LOG" ]
}

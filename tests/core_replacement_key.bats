#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/../core.sh"
  eval "$(sed -n '/^read_replacement_key() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^verify_arvan_access_with_replacement_key() {/,/^}$/p' "$source_file")"

  export MOCK_FLOW_LOG="${BATS_TEST_TMPDIR}/replacement-flow.log"
  : > "$MOCK_FLOW_LOG"
  DOMAIN="example.com"
  LOG_DIR="${BATS_TEST_TMPDIR}/logs"
  ARVAN_ACCESS_KEY="initial-invalid-key"
  MOCK_VERIFY_SEQUENCE="10 0"
  MOCK_VERIFY_CALLS=0
  MOCK_REPLACEMENT_KEY="corrected-test-key"
  MOCK_READ_FAILURE=0

  verify_arvan_access() {
    local -a statuses=()
    read -r -a statuses <<< "$MOCK_VERIFY_SEQUENCE"
    local status="${statuses[$MOCK_VERIFY_CALLS]:-20}"
    printf 'verify-call=%s key=%s\n' "$MOCK_VERIFY_CALLS" "$ARVAN_ACCESS_KEY" >> "$MOCK_FLOW_LOG"
    MOCK_VERIFY_CALLS=$((MOCK_VERIFY_CALLS + 1))
    return "$status"
  }

  read_replacement_key() {
    printf 'read-replacement\n' >> "$MOCK_FLOW_LOG"
    [[ "$MOCK_READ_FAILURE" -eq 0 ]] || return 1
    REPLACEMENT_KEY="$MOCK_REPLACEMENT_KEY"
  }

  die() {
    printf 'DIE: %s\n' "$*" >&2
    exit 1
  }
}

strict_flow() {
  (
    set -Eeuo pipefail
    verify_arvan_access_with_replacement_key
    printf 'FINAL_KEY=%s\n' "$ARVAN_ACCESS_KEY"
  )
}

@test "rejected API key can be replaced without re-entering domain or options" {
  MOCK_VERIFY_SEQUENCE="10 0"
  MOCK_REPLACEMENT_KEY="corrected-test-key"
  export MOCK_VERIFY_SEQUENCE MOCK_REPLACEMENT_KEY

  run strict_flow

  [ "$status" -eq 0 ]
  [[ "$output" == *"FINAL_KEY=corrected-test-key"* ]]
  [ "$(grep -c '^verify-call=' "$MOCK_FLOW_LOG")" -eq 2 ]
  grep -Fq 'verify-call=0 key=initial-invalid-key' "$MOCK_FLOW_LOG"
  grep -Fq 'verify-call=1 key=corrected-test-key' "$MOCK_FLOW_LOG"
  [ "$(grep -c '^read-replacement$' "$MOCK_FLOW_LOG")" -eq 1 ]
}

@test "zone visibility failure also allows a corrected key" {
  MOCK_VERIFY_SEQUENCE="11 0"
  export MOCK_VERIFY_SEQUENCE

  run strict_flow

  [ "$status" -eq 0 ]
  [[ "$output" == *"FINAL_KEY=corrected-test-key"* ]]
  [ "$(grep -c '^read-replacement$' "$MOCK_FLOW_LOG")" -eq 1 ]
}

@test "network or malformed API status fails closed without prompting for another key" {
  MOCK_VERIFY_SEQUENCE="20"
  export MOCK_VERIFY_SEQUENCE

  run strict_flow

  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not verify ArvanCloud access"* ]]
  [ "$(grep -c '^read-replacement$' "$MOCK_FLOW_LOG" || true)" -eq 0 ]
}

@test "empty replacement key cancels safely" {
  MOCK_VERIFY_SEQUENCE="10"
  MOCK_REPLACEMENT_KEY=""
  export MOCK_VERIFY_SEQUENCE MOCK_REPLACEMENT_KEY

  run strict_flow

  [ "$status" -ne 0 ]
  [[ "$output" == *"Access verification cancelled"* ]]
  [[ "$output" != *"FINAL_KEY="* ]]
}

@test "replacement keys containing a carriage return are rejected" {
  MOCK_VERIFY_SEQUENCE="10"
  MOCK_REPLACEMENT_KEY=$'bad-key\r'
  export MOCK_VERIFY_SEQUENCE MOCK_REPLACEMENT_KEY

  run strict_flow

  [ "$status" -ne 0 ]
  [[ "$output" == *"single line"* ]]
  [[ "$output" != *"FINAL_KEY="* ]]
}

@test "replacement keys containing a newline are rejected" {
  MOCK_VERIFY_SEQUENCE="10"
  MOCK_REPLACEMENT_KEY=$'bad-key\nsecond-line'
  export MOCK_VERIFY_SEQUENCE MOCK_REPLACEMENT_KEY

  run strict_flow

  [ "$status" -ne 0 ]
  [[ "$output" == *"single line"* ]]
  [[ "$output" != *"FINAL_KEY="* ]]
}

@test "failed terminal read does not continue with an empty or stale key" {
  MOCK_VERIFY_SEQUENCE="10"
  MOCK_READ_FAILURE=1
  export MOCK_VERIFY_SEQUENCE MOCK_READ_FAILURE

  run strict_flow

  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not read the replacement key"* ]]
  [[ "$output" != *"FINAL_KEY="* ]]
}

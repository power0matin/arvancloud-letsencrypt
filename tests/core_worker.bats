#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/../core.sh"
  eval "$(sed -n '/^run_worker() {/,/^}$/p' "$source_file")"

  export TEST_LOG_DIR="${BATS_TEST_TMPDIR}/worker-logs"
  export MOCK_WORKER_LOG="${BATS_TEST_TMPDIR}/worker-mock.log"
  mkdir -p "$TEST_LOG_DIR"
  : > "$MOCK_WORKER_LOG"

  LOG_DIR="$TEST_LOG_DIR"
  DOMAIN="example.com"
  BACKGROUND="1"
  MOCK_ISSUE_STATUS=0

  issue_and_install() {
    printf 'MOCK_ISSUE domain=%s background=%s\n' "$DOMAIN" "$BACKGROUND"
    printf 'private-key-marker-must-not-appear\n' >/dev/null
    return "$MOCK_ISSUE_STATUS"
  }

  log() {
    printf '[mock] %s\n' "$*"
  }
}

strict_worker() {
  (
    set -Eeuo pipefail
    run_worker
  )
}

@test "background worker writes issuance output and completion marker to the issuance log" {
  BACKGROUND=1
  export BACKGROUND

  run strict_worker

  [ "$status" -eq 0 ]
  [ ! -s "$MOCK_WORKER_LOG" ]
  grep -Fq 'MOCK_ISSUE domain=example.com background=1' "$TEST_LOG_DIR/acme-issue.log"
  grep -Fq 'Completed certificate job for example.com' "$TEST_LOG_DIR/acme-issue.log"
  [[ "$output" != *"MOCK_ISSUE"* ]]
}

@test "failed background issuance returns nonzero and does not write a completion marker" {
  BACKGROUND=1
  MOCK_ISSUE_STATUS=7
  export BACKGROUND MOCK_ISSUE_STATUS

  run strict_worker

  [ "$status" -ne 0 ]
  grep -Fq 'MOCK_ISSUE domain=example.com background=1' "$TEST_LOG_DIR/acme-issue.log"
  ! grep -Fq 'Completed certificate job for example.com' "$TEST_LOG_DIR/acme-issue.log"
}

@test "foreground worker streams issuance output and persists it to the log" {
  BACKGROUND=0
  export BACKGROUND

  run strict_worker

  [ "$status" -eq 0 ]
  [[ "$output" == *"MOCK_ISSUE domain=example.com background=0"* ]]
  grep -Fq 'MOCK_ISSUE domain=example.com background=0' "$TEST_LOG_DIR/acme-issue.log"
  grep -Fq 'Completed certificate job for example.com' "$TEST_LOG_DIR/acme-issue.log"
}

@test "failed foreground issuance returns nonzero and omits completion marker" {
  BACKGROUND=0
  MOCK_ISSUE_STATUS=9
  export BACKGROUND MOCK_ISSUE_STATUS

  run strict_worker

  [ "$status" -ne 0 ]
  ! grep -Fq 'Completed certificate job for example.com' "$TEST_LOG_DIR/acme-issue.log"
}

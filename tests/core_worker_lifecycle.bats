#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/../core.sh"
  eval "$(sed -n '/^run_worker() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^start_background_worker() {/,/^}$/p' "$source_file")"

  export TEST_LOG_DIR="${BATS_TEST_TMPDIR}/worker-lifecycle"
  mkdir -p "$TEST_LOG_DIR"
  LOG_DIR="$TEST_LOG_DIR"
  INSTALL_DIR="${BATS_TEST_TMPDIR}/cert-output"
  DOMAIN="example.com"
  BACKGROUND=1
  MOCK_WORKER_STATUS=0
  MOCK_SLEEP_SECONDS=0.2
}

log() {
  printf '%s\n' "$*" >> "$LOG_DIR/install.log"
}

issue_and_install() {
  printf 'worker-started pid=%s\n' "$BASHPID"
  sleep "$MOCK_SLEEP_SECONDS"
  printf 'worker-finished domain=%s status=%s\n' "$DOMAIN" "$MOCK_WORKER_STATUS"
  return "$MOCK_WORKER_STATUS"
}

launch_and_exit_parent() {
  (
    set -Eeuo pipefail
    start_background_worker
    printf 'parent-exiting\n' >> "$LOG_DIR/parent.log"
  )
}

wait_for_log_text() {
  local path="$1" text="$2" attempt
  for attempt in {1..50}; do
    [[ -f "$path" ]] && grep -Fq "$text" "$path" && return 0
    sleep 0.1
  done
  printf 'Timeout waiting for [%s] in [%s]. Files under %s:\\n' "$text" "$path" "$LOG_DIR" >&2
  find "$LOG_DIR" -maxdepth 2 -type f -print -exec sh -c 'echo "--- $1"; cat "$1"' _ {} \\; >&2 || true
  return 1
}

@test "detached worker survives parent exit and writes a completion marker" {
  run launch_and_exit_parent

  [ "$status" -eq 0 ]
  grep -Fq 'parent-exiting' "$LOG_DIR/parent.log"
  wait_for_log_text "$LOG_DIR/acme-issue.log" 'Completed certificate job for example.com'
  grep -Fq 'worker-started pid=' "$LOG_DIR/acme-issue.log"
  grep -Fq 'worker-finished domain=example.com status=0' "$LOG_DIR/acme-issue.log"
  grep -Fq 'Started PID ' "$LOG_DIR/install.log"
}

@test "detached worker failure survives parent exit and keeps the nonzero status" {
  MOCK_WORKER_STATUS=7
  export MOCK_WORKER_STATUS

  run launch_and_exit_parent

  [ "$status" -eq 0 ]
  grep -Fq 'parent-exiting' "$LOG_DIR/parent.log"
  wait_for_log_text "$LOG_DIR/acme-issue.log" 'failed with exit status 7'
  ! grep -Fq 'Completed certificate job for example.com' "$LOG_DIR/acme-issue.log"
}


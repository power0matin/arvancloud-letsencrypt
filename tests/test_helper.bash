# Shared compatibility helpers for Bats versions supplied by Ubuntu repositories.
# SPDX-License-Identifier: GPL-3.0-or-later

ensure_test_tmpdir() {
  if [[ -n "${BATS_TEST_TMPDIR:-}" ]]; then
    BATS_TEST_TMPDIR_FALLBACK=0
    export BATS_TEST_TMPDIR
    return 0
  fi

  BATS_TEST_TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/arvancloud-letsencrypt-bats.XXXXXX")" || return 1
  BATS_TEST_TMPDIR_FALLBACK=1
  export BATS_TEST_TMPDIR BATS_TEST_TMPDIR_FALLBACK
}

teardown() {
  if [[ "${BATS_TEST_TMPDIR_FALLBACK:-0}" == "1" && -n "${BATS_TEST_TMPDIR:-}" ]]; then
    rm -rf -- "$BATS_TEST_TMPDIR"
  fi
}

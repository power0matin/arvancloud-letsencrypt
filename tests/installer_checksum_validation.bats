#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/../install.sh"
  eval "$(sed -n '/^prepare_release_downloads() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^download_verified_component() {/,/^}$/p' "$source_file")"

  export TMPDIR="$BATS_TEST_TMPDIR"
  export MOCK_CURL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  : > "$MOCK_CURL_LOG"

  REPOSITORY="power0matin/arvancloud-letsencrypt"
  SCRIPT_VERSION="1.1.4"
  RELEASE_TAG="v${SCRIPT_VERSION}"
  RAW_BASE="https://raw.githubusercontent.com/${REPOSITORY}/${RELEASE_TAG}"
  RELEASE_BASE="https://github.com/${REPOSITORY}/releases/download/${RELEASE_TAG}"
  TMP_DIR=""

  MOCK_COMPONENT_BODY="mock-component-content"
  MOCK_DIGEST="$(printf '%s' "$MOCK_COMPONENT_BODY" | sha256sum | awk '{print $1}')"
  MOCK_MANIFEST="$(printf '%s  core.sh\n' "$MOCK_DIGEST")"
  MOCK_MANIFEST_FAIL=0
  MOCK_COMPONENT_FAIL=0

  curl() {
    local output_path="$2" url="$3"
    [[ "$1" == "-fsSLo" && $# -eq 3 ]] || return 64
    printf '%s\n' "$url" >> "$MOCK_CURL_LOG"
    case "$url" in
      "${RELEASE_BASE}/SHA256SUMS")
        [[ "$MOCK_MANIFEST_FAIL" -eq 0 ]] || return 22
        printf '%s' "$MOCK_MANIFEST" > "$output_path"
        ;;
      "${RAW_BASE}/core.sh")
        [[ "$MOCK_COMPONENT_FAIL" -eq 0 ]] || return 22
        printf '%s' "$MOCK_COMPONENT_BODY" > "$output_path"
        ;;
      *) return 22 ;;
    esac
  }

  die() {
    printf 'DIE: %s\n' "$*" >&2
    exit 1
  }
}

@test "valid pinned component matches the release SHA256SUMS manifest" {
  run download_verified_component core.sh

  [ "$status" -eq 0 ]
  grep -Fq '/releases/download/v1.1.4/SHA256SUMS' "$MOCK_CURL_LOG"
  grep -Fq '/v1.1.4/core.sh' "$MOCK_CURL_LOG"
  local downloaded
  downloaded="$(find "$BATS_TEST_TMPDIR" -type f -name core.sh -print -quit)"
  [ -n "$downloaded" ]
  [ "$(cat "$downloaded")" = "$MOCK_COMPONENT_BODY" ]
}

@test "tampered component checksum is rejected" {
  MOCK_MANIFEST="$(printf '%s  core.sh\n' "0000000000000000000000000000000000000000000000000000000000000000")"

  run download_verified_component core.sh

  [ "$status" -ne 0 ]
  [[ "$output" == *"Checksum verification failed for core.sh"* ]]
}

@test "missing component checksum entry is rejected" {
  MOCK_MANIFEST="$(printf '%s  menu.sh\n' "$MOCK_DIGEST")"

  run download_verified_component core.sh

  [ "$status" -ne 0 ]
  [[ "$output" == *"does not contain exactly one entry"* ]]
}

@test "duplicate component checksum entries are rejected" {
  MOCK_MANIFEST="$(printf '%s  core.sh\n%s  core.sh\n' "$MOCK_DIGEST" "$MOCK_DIGEST")"

  run download_verified_component core.sh

  [ "$status" -ne 0 ]
  [[ "$output" == *"does not contain exactly one entry"* ]]
}

@test "unavailable checksum manifest fails before fetching the component" {
  MOCK_MANIFEST_FAIL=1

  run download_verified_component core.sh

  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not download the checksum manifest"* ]]
  [ "$(wc -l < "$MOCK_CURL_LOG")" -eq 1 ]
}

@test "unavailable pinned component is rejected" {
  MOCK_COMPONENT_FAIL=1

  run download_verified_component core.sh

  [ "$status" -ne 0 ]
  [[ "$output" == *"Could not download core.sh"* ]]
  [ "$(wc -l < "$MOCK_CURL_LOG")" -eq 2 ]
}

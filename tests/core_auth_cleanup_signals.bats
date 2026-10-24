#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

setup() {
  SOURCE_CORE="${BATS_TEST_DIRNAME}/../core.sh"
  export SOURCE_CORE
}

@test "EXIT trap removes the temporary authorization file" {
  local auth_file="${BATS_TEST_TMPDIR}/auth-exit.conf"
  printf 'mock secret\n' > "$auth_file"

  run bash -c '
    set -Eeuo pipefail
    eval "$(sed -n "/^cleanup_auth_config() {/,/^}$/p" "$1")"
    eval "$(sed -n "/^trap cleanup_auth_config EXIT/,+3p" "$1")"
    AUTH_CONFIG_FILE="$2"
    exit 0
  ' _ "$SOURCE_CORE" "$auth_file"

  [ "$status" -eq 0 ]
  [ ! -e "$auth_file" ]
}

@test "HUP trap exits and EXIT cleanup removes the temporary authorization file" {
  local auth_file="${BATS_TEST_TMPDIR}/auth-hup.conf"
  printf 'mock secret\n' > "$auth_file"

  run bash -c '
    set -Eeuo pipefail
    eval "$(sed -n "/^cleanup_auth_config() {/,/^}$/p" "$1")"
    eval "$(sed -n "/^trap cleanup_auth_config EXIT/,+3p" "$1")"
    AUTH_CONFIG_FILE="$2"
    kill -HUP "$$"
  ' _ "$SOURCE_CORE" "$auth_file"

  [ "$status" -eq 129 ]
  [ ! -e "$auth_file" ]
}

@test "INT trap exits and EXIT cleanup removes the temporary authorization file" {
  local auth_file="${BATS_TEST_TMPDIR}/auth-int.conf"
  printf 'mock secret\n' > "$auth_file"

  run bash -c '
    set -Eeuo pipefail
    eval "$(sed -n "/^cleanup_auth_config() {/,/^}$/p" "$1")"
    eval "$(sed -n "/^trap cleanup_auth_config EXIT/,+3p" "$1")"
    AUTH_CONFIG_FILE="$2"
    kill -INT "$$"
  ' _ "$SOURCE_CORE" "$auth_file"

  [ "$status" -eq 130 ]
  [ ! -e "$auth_file" ]
}

@test "TERM trap exits and EXIT cleanup removes the temporary authorization file" {
  local auth_file="${BATS_TEST_TMPDIR}/auth-term.conf"
  printf 'mock secret\n' > "$auth_file"

  run bash -c '
    set -Eeuo pipefail
    eval "$(sed -n "/^cleanup_auth_config() {/,/^}$/p" "$1")"
    eval "$(sed -n "/^trap cleanup_auth_config EXIT/,+3p" "$1")"
    AUTH_CONFIG_FILE="$2"
    kill -TERM "$$"
  ' _ "$SOURCE_CORE" "$auth_file"

  [ "$status" -eq 143 ]
  [ ! -e "$auth_file" ]
}

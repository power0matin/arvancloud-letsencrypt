#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  local source_file="${BATS_TEST_DIRNAME}/staging/run-acme-staging.sh"
  eval "$(sed -n '/^read_staging_domain() {/,/^}$/p' "$source_file")"
  eval "$(sed -n '/^read_staging_api_key() {/,/^}$/p' "$source_file")"
}

@test "domain secret is normalized and cleared after validation" {
  ARVAN_STAGING_DOMAIN="ACME-TEST.Example.COM."
  export ARVAN_STAGING_DOMAIN

  read_staging_domain

  [ "$DOMAIN" = "acme-test.example.com" ]
  [ -z "${ARVAN_STAGING_DOMAIN+x}" ]
}

@test "noninteractive domain without acme-test prefix is rejected" {
  ARVAN_STAGING_DOMAIN="example.com"
  export ARVAN_STAGING_DOMAIN

  if read_staging_domain; then status=0; else status=$?; fi

  [ "$status" -eq 2 ]
  [ -z "${DOMAIN:-}" ]
}

@test "malformed test domain is rejected" {
  ARVAN_STAGING_DOMAIN="acme-test..example.com"
  export ARVAN_STAGING_DOMAIN

  if read_staging_domain; then status=0; else status=$?; fi

  [ "$status" -eq 2 ]
}

@test "environment API key is exported for acme.sh and removed from its original variable" {
  ARVAN_STAGING_API_KEY="mock-staging-secret"
  export ARVAN_STAGING_API_KEY
  local output_file="${BATS_TEST_TMPDIR}/staging-key-output"

  read_staging_api_key > "$output_file"

  [ "$Arvan_Token" = "mock-staging-secret" ]
  [[ "$(declare -p Arvan_Token)" == declare\\ -x* ]]
  [ -z "${ARVAN_STAGING_API_KEY+x}" ]
  ! grep -Fq "mock-staging-secret" "$output_file"
}

@test "multiline API key is rejected and cleared" {
  ARVAN_STAGING_API_KEY=$'bad-key\nsecond-line'
  export ARVAN_STAGING_API_KEY

  if read_staging_api_key; then status=0; else status=$?; fi

  [ "$status" -eq 2 ]
  [ -z "${Arvan_Token+x}" ]
  [ -z "${ARVAN_STAGING_API_KEY+x}" ]
}

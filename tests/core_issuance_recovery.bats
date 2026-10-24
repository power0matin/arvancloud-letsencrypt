#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-3.0-or-later

source "${BATS_TEST_DIRNAME}/test_helper.bash"

setup() {
  ensure_test_tmpdir
  eval "$(sed -n '/^issue_and_install() {/,/^}$/p' "${BATS_TEST_DIRNAME}/../core.sh")"

  export MOCK_LOG="${BATS_TEST_TMPDIR}/acme.log"
  export MOCK_ACME_HOME="${BATS_TEST_TMPDIR}/acme-home"
  export MOCK_DOMAIN="example.com"
  export MOCK_EXPECTED_TOKEN="test-only-token"
  export MOCK_ISSUE_STATUS=0
  export MOCK_CERT_AVAILABLE=1
  export MOCK_INSTALL_STATUS=0
  export MOCK_PARTIAL_INSTALL=0
  : > "$MOCK_LOG"

  DOMAIN="$MOCK_DOMAIN"
  INSTALL_DIR="${BATS_TEST_TMPDIR}/cert-output"
  ACME_HOME="$MOCK_ACME_HOME"
  ACME_BIN="${BATS_TEST_TMPDIR}/bin/acme.sh"
  LOG_DIR="${BATS_TEST_TMPDIR}/logs"
  ARVAN_ACCESS_KEY="$MOCK_EXPECTED_TOKEN"
  DNSSLEEP="1"
  RELOAD_CMD=""
  DEBUG="0"
  FORCE="0"

  mkdir -p "${BATS_TEST_TMPDIR}/bin" "$MOCK_ACME_HOME"
  cat > "$ACME_BIN" <<'MOCK_ACME'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'ACME' >> "$MOCK_LOG"
printf ' %q' "$@" >> "$MOCK_LOG"
printf '\n' >> "$MOCK_LOG"

case " $* " in
  *" --issue "*)
    [[ "${Arvan_Token:-}" == "$MOCK_EXPECTED_TOKEN" ]] || exit 97
    if [[ "$MOCK_CERT_AVAILABLE" == "1" ]]; then
      mkdir -p "$MOCK_ACME_HOME/${MOCK_DOMAIN}_ecc"
      printf 'mock-source-certificate\n' > "$MOCK_ACME_HOME/${MOCK_DOMAIN}_ecc/fullchain.cer"
    fi
    exit "$MOCK_ISSUE_STATUS"
    ;;
  *" --install-cert "*)
    [[ "$MOCK_INSTALL_STATUS" == "0" ]] || exit "$MOCK_INSTALL_STATUS"
    key_file=""
    fullchain_file=""
    cert_file=""
    chain_file=""
    while (($#)); do
      case "$1" in
        --key-file) key_file="$2"; shift 2 ;;
        --fullchain-file) fullchain_file="$2"; shift 2 ;;
        --cert-file) cert_file="$2"; shift 2 ;;
        --ca-file) chain_file="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    mkdir -p "$(dirname "$key_file")"
    printf 'mock-private-key\n' > "$key_file"
    printf 'mock-certificate\n' > "$cert_file"
    if [[ "$MOCK_PARTIAL_INSTALL" != "1" ]]; then
      printf 'mock-fullchain\n' > "$fullchain_file"
      printf 'mock-intermediate\n' > "$chain_file"
    fi
    exit 0
    ;;
  *)
    printf 'Unexpected ACME command.\n' >&2
    exit 98
    ;;
esac
MOCK_ACME
  chmod 700 "$ACME_BIN"

  cat > "${BATS_TEST_TMPDIR}/bin/openssl" <<'MOCK_OPENSSL'
#!/usr/bin/env bash
exit 0
MOCK_OPENSSL
  chmod 700 "${BATS_TEST_TMPDIR}/bin/openssl"
  PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export PATH

  log() { printf 'LOG\t%s\n' "$*" >> "$MOCK_LOG"; }
  die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
}

strict_issue_and_install() {
  (
    set -Eeuo pipefail
    issue_and_install
  )
}

acme_install_count() {
  awk '/^ACME / && /--install-cert/ { count++ } END { print count + 0 }' "$MOCK_LOG"
}

success_was_logged() {
  grep -Fq $'LOG\tCertificate installed successfully' "$MOCK_LOG"
}

@test "successful issuance installs all files with restrictive modes" {
  run strict_issue_and_install

  [ "$status" -eq 0 ]
  [ -s "$INSTALL_DIR/privkey.pem" ]
  [ -s "$INSTALL_DIR/cert.pem" ]
  [ -s "$INSTALL_DIR/chain.pem" ]
  [ -s "$INSTALL_DIR/fullchain.pem" ]
  [ "$(stat -c '%a' "$INSTALL_DIR/privkey.pem")" = "600" ]
  [ "$(stat -c '%a' "$INSTALL_DIR/cert.pem")" = "644" ]
  [ "$(acme_install_count)" -eq 1 ]
  success_was_logged
}

@test "acme exit code 2 is accepted only when the expected certificate exists" {
  MOCK_ISSUE_STATUS=2
  export MOCK_ISSUE_STATUS

  run strict_issue_and_install

  [ "$status" -eq 0 ]
  [ "$(acme_install_count)" -eq 1 ]
  success_was_logged
}

@test "acme exit code 2 without an existing certificate fails before installation" {
  MOCK_ISSUE_STATUS=2
  MOCK_CERT_AVAILABLE=0
  export MOCK_ISSUE_STATUS MOCK_CERT_AVAILABLE

  run strict_issue_and_install

  [ "$status" -ne 0 ]
  [ "$(acme_install_count)" -eq 0 ]
  ! success_was_logged
}

@test "failed issuance never invokes certificate installation" {
  MOCK_ISSUE_STATUS=1
  export MOCK_ISSUE_STATUS

  run strict_issue_and_install

  [ "$status" -ne 0 ]
  [ "$(acme_install_count)" -eq 0 ]
  ! success_was_logged
}

@test "failed acme.sh install step is not reported as success" {
  MOCK_INSTALL_STATUS=1
  export MOCK_INSTALL_STATUS

  run strict_issue_and_install

  [ "$status" -ne 0 ]
  [ "$(acme_install_count)" -eq 1 ]
  ! success_was_logged
}

@test "partial certificate installation fails instead of reporting success" {
  MOCK_PARTIAL_INSTALL=1
  export MOCK_PARTIAL_INSTALL

  run strict_issue_and_install

  [ "$status" -ne 0 ]
  [ -s "$INSTALL_DIR/privkey.pem" ]
  [ ! -s "$INSTALL_DIR/fullchain.pem" ]
  ! success_was_logged
}

@test "reload command is forwarded as a single argument" {
  RELOAD_CMD="systemctl reload nginx"

  run strict_issue_and_install

  [ "$status" -eq 0 ]
  grep -Fq 'systemctl\ reload\ nginx' "$MOCK_LOG"
  success_was_logged
}

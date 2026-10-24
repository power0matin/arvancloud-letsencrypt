#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -Eeuo pipefail

readonly ACME_SCRIPT="${ACME_SCRIPT:-/root/.acme.sh/acme.sh}"
STAGING_HOME=""

cleanup() {
  local status=$?
  trap - EXIT
  unset Arvan_Token ARVAN_STAGING_API_KEY ARVAN_STAGING_DOMAIN 2>/dev/null || true
  if [[ -n "${STAGING_HOME:-}" && -d "$STAGING_HOME" ]]; then
    rm -rf -- "$STAGING_HOME"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

usage() {
  printf 'Usage: sudo bash %s /path/to/src/dns_arvan.sh\n' "$0"
  printf 'Runs a disposable ACME staging test; it does not install a certificate into a service path.\n'
}

read_staging_domain() {
  local candidate="${ARVAN_STAGING_DOMAIN:-}"
  if [[ -z "$candidate" ]]; then
    printf 'Dedicated ArvanCloud test subdomain (not your production hostname): ' > /dev/tty
    IFS= read -r candidate < /dev/tty || { printf 'Could not read domain from terminal.\n' >&2; return 1; }
  elif [[ "$candidate" != acme-test.* ]]; then
    printf 'Non-interactive staging domain must start with acme-test.\n' >&2
    return 2
  fi

  candidate="$(printf '%s' "$candidate" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')"
  [[ "$candidate" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || {
    printf 'Invalid fully-qualified domain. Use a dedicated test subdomain you control.\n' >&2
    return 2
  }
  DOMAIN="$candidate"
  unset ARVAN_STAGING_DOMAIN
}

read_staging_api_key() {
  if [[ -n "${ARVAN_STAGING_API_KEY:-}" ]]; then
    Arvan_Token="$ARVAN_STAGING_API_KEY"
    unset ARVAN_STAGING_API_KEY
  else
    printf 'ArvanCloud API key (hidden; it is kept only in the disposable staging home): ' > /dev/tty
    IFS= read -r -s Arvan_Token < /dev/tty || { printf '\nCould not read API key.\n' >&2; return 1; }
    printf '\n' > /dev/tty
  fi

  [[ -n "${Arvan_Token:-}" ]] || {
    unset Arvan_Token
    printf 'API key is required.\n' >&2
    return 2
  }
  [[ "$Arvan_Token" != *$'\n'* && "$Arvan_Token" != *$'\r'* ]] || {
    unset Arvan_Token
    printf 'API key must be a single line.\n' >&2
    return 2
  }
  export Arvan_Token
}

[[ "$(id -u)" == "0" ]] || { printf 'Run this test as root, for example with sudo.\n' >&2; exit 1; }
[[ $# -eq 1 ]] || { usage >&2; exit 2; }
[[ -x "$ACME_SCRIPT" ]] || { printf 'acme.sh is not installed at %s. Install the project first.\n' "$ACME_SCRIPT" >&2; exit 1; }

SOURCE_PLUGIN="$(readlink -f -- "$1")"
readonly SOURCE_PLUGIN
[[ -f "$SOURCE_PLUGIN" ]] || { printf 'DNS plugin source does not exist: %s\n' "$SOURCE_PLUGIN" >&2; exit 1; }

DOMAIN=""
read_staging_domain || exit "$?"

STAGING_HOME="$(mktemp -d /root/acme-arvan-staging.XXXXXX)"
chmod 700 "$STAGING_HOME"
umask 077
mkdir -p "$STAGING_HOME/dnsapi" "$STAGING_HOME/config" "$STAGING_HOME/certs"
install -m 700 "$ACME_SCRIPT" "$STAGING_HOME/acme.sh"
install -m 600 "$SOURCE_PLUGIN" "$STAGING_HOME/dnsapi/dns_arvan.sh"

read_staging_api_key || exit "$?"

printf '\nRunning ACME staging issuance for %s and *.%s.\n' "$DOMAIN" "$DOMAIN"
printf 'No certificate deployment step will run; production certificate paths are not used.\n\n'
if "$STAGING_HOME/acme.sh" \
  --home "$STAGING_HOME" \
  --config-home "$STAGING_HOME/config" \
  --cert-home "$STAGING_HOME/certs" \
  --server letsencrypt_test \
  --issue --dns dns_arvan \
  -d "$DOMAIN" -d "*.$DOMAIN" \
  --dnssleep 180; then
  printf '\nACME staging issuance succeeded for %s.\n' "$DOMAIN"
else
  status=$?
  printf '\nACME staging issuance failed (exit %s). Check the message above. The temporary account, credentials, and staging certificate files will be removed.\n' "$status" >&2
  exit "$status"
fi

printf 'Cleanup will remove the temporary staging home: %s\n' "$STAGING_HOME"

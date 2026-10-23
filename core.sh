#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_VERSION="1.1.0"
readonly ACME_HOME="/root/.acme.sh"
readonly ACME_BIN="${ACME_HOME}/acme.sh"
readonly DNSAPI_PATH="${ACME_HOME}/dnsapi/dns_arvan.sh"
readonly LOG_DIR="/var/log/arvancloud-letsencrypt"
readonly LOCK_FILE="/run/lock/arvancloud-letsencrypt.lock"
readonly ARVAN_API_URL="https://napi.arvancloud.ir/cdn/4.0/domains"

DOMAIN=""
EMAIL=""
INSTALL_DIR=""
RELOAD_CMD=""
DNSSLEEP="180"
USE_XUI="0"
BACKGROUND="0"
FORCE="0"
DEBUG="0"
WORKER="0"

usage() {
  cat <<'EOF'
Usage:
  install.sh --domain example.com [options]

Required:
  --domain DOMAIN          Base domain managed by Arvan Cloud DNS

Options:
  --email EMAIL             Email used when installing acme.sh
  --install-dir DIR        Certificate output directory
  --reload-cmd COMMAND     Command run after a successful certificate install
  --x-ui                    Use /root/cert/DOMAIN and x-ui restart
  --background              Keep issuance running after SSH disconnect
  --force                   Force a new issuance
  --dns-sleep SECONDS       DNS propagation wait time (default: 180)
  --debug                   Enable acme.sh debug output
  --help                    Show this help

Environment:
  ARVAN_ACCESS_KEY          Arvan Cloud access key; otherwise prompted securely
  ACME_EMAIL                Default email if --email is not supplied
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

on_error() {
  local line="$1"
  printf 'ERROR: command failed at line %s. Check %s for details.\n' "$line" "${LOG_DIR}/install.log" >&2
}

trap 'on_error "$LINENO"' ERR

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      [[ $# -ge 2 ]] || die "--domain requires a value"
      DOMAIN="$2"
      shift 2
      ;;
    --email)
      [[ $# -ge 2 ]] || die "--email requires a value"
      EMAIL="$2"
      shift 2
      ;;
    --install-dir)
      [[ $# -ge 2 ]] || die "--install-dir requires a value"
      INSTALL_DIR="$2"
      shift 2
      ;;
    --reload-cmd)
      [[ $# -ge 2 ]] || die "--reload-cmd requires a value"
      RELOAD_CMD="$2"
      shift 2
      ;;
    --dns-sleep)
      [[ $# -ge 2 ]] || die "--dns-sleep requires a value"
      DNSSLEEP="$2"
      shift 2
      ;;
    --x-ui)
      USE_XUI="1"
      shift
      ;;
    --background)
      BACKGROUND="1"
      shift
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    --debug)
      DEBUG="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

[[ "$(id -u)" == "0" ]] || die "Run this script as root."
[[ -n "$DOMAIN" ]] || die "--domain is required."

EMAIL="${EMAIL:-${ACME_EMAIL:-}}"

DOMAIN="$(printf '%s' "$DOMAIN" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')"
[[ -n "$DOMAIN" && ${#DOMAIN} -le 253 && "$DOMAIN" == *.* ]] || die "Enter a fully-qualified base domain such as example.com."
[[ "$DOMAIN" != *'*'* && "$DOMAIN" != *'/'* && "$DOMAIN" != *' '* ]] || die "Pass the base domain only, without wildcard or path."
IFS='.' read -r -a DOMAIN_LABELS <<< "$DOMAIN"
for DOMAIN_LABEL in "${DOMAIN_LABELS[@]}"; do
  [[ ${#DOMAIN_LABEL} -ge 1 && ${#DOMAIN_LABEL} -le 63 ]] || die "Invalid DNS label in domain: $DOMAIN"
  [[ "$DOMAIN_LABEL" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || die "Invalid DNS label in domain: $DOMAIN"
done
[[ "$DNSSLEEP" =~ ^[0-9]+$ ]] || die "--dns-sleep must be an integer."
[[ "$DNSSLEEP" -le 3600 ]] || die "--dns-sleep must not exceed 3600 seconds."

if [[ "$USE_XUI" == "1" ]]; then
  INSTALL_DIR="${INSTALL_DIR:-/root/cert/${DOMAIN}}"
  RELOAD_CMD="${RELOAD_CMD:-x-ui restart}"
  command -v x-ui >/dev/null 2>&1 || die "--x-ui was requested but x-ui was not found."
else
  INSTALL_DIR="${INSTALL_DIR:-/etc/ssl/acme/${DOMAIN}}"
fi

[[ "$INSTALL_DIR" == /* && "$INSTALL_DIR" != "/" ]] || die "--install-dir must be an absolute path other than /."

mkdir -p "$LOG_DIR"
exec > >(tee -a "${LOG_DIR}/install.log") 2>&1

if [[ "$WORKER" != "1" ]]; then
  umask 077
  exec 9>"$LOCK_FILE"
  flock -n 9 || die "Another arvancloud-letsencrypt process is already running."
fi

install_dependencies() {
  export DEBIAN_FRONTEND=noninteractive
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v openssl >/dev/null 2>&1 || missing+=(openssl)
  command -v jq >/dev/null 2>&1 || missing+=(jq)
  command -v crontab >/dev/null 2>&1 || missing+=(cron)
  if ((${#missing[@]})); then
    log "Installing prerequisites: ${missing[*]}"
    apt-get update
    apt-get install -y "${missing[@]}"
  fi
}

install_acme() {
  if [[ ! -x "$ACME_BIN" ]]; then
    log "Installing acme.sh"
    if [[ -n "$EMAIL" ]]; then
      curl -fsSL https://get.acme.sh | sh -s email="$EMAIL"
    else
      curl -fsSL https://get.acme.sh | sh
    fi
  fi
  [[ -x "$ACME_BIN" ]] || die "acme.sh installation failed."
  chmod 700 "$ACME_HOME"
}

install_dns_plugin() {
  mkdir -p "${ACME_HOME}/dnsapi"
  if [[ -f "$DNSAPI_PATH" ]]; then
    local backup
    backup="${DNSAPI_PATH}.backup-$(date -u '+%Y%m%dT%H%M%SZ')"
    cp -a "$DNSAPI_PATH" "$backup"
    log "Backed up existing DNS plugin to $backup"
  fi
  install -m 700 /dev/stdin "$DNSAPI_PATH" <<'PLUGIN'
#!/usr/bin/env sh

# This file is embedded in core.sh to support one-line installation. Keep both copies aligned.

# shellcheck disable=SC2034
dns_arvan_info='ArvanCloud DNS API integration

Site: https://www.arvancloud.ir
Docs: https://github.com/acmesh-official/acme.sh/wiki/dnsapi
Options:
  Arvan_Token API access key
'

ARVAN_API_URL="https://napi.arvancloud.ir/cdn/4.0/domains"

dns_arvan_add() {
  fulldomain="$1"
  txtvalue="$2"
  _info "Using Arvan"
  Arvan_Token="${Arvan_Token:-$(_readaccountconf_mutable Arvan_Token)}"
  [ -n "$Arvan_Token" ] || { _err "Arvan_Token is not available."; return 1; }
  _saveaccountconf_mutable Arvan_Token "$Arvan_Token"
  _get_root "$fulldomain" || { _err "Unable to find the Arvan root zone."; return 1; }

  data="{\"type\":\"TXT\",\"name\":\"$_sub_domain\",\"value\":{\"text\":\"$txtvalue\"},\"ttl\":120}"
  if _arvan_rest POST "$_domain/dns-records" "$data" && \
     { _contains "$response" "$txtvalue" || _contains "$response" "Record Data is duplicate"; }; then
    _info "TXT record added or already exists."
    return 0
  fi
  _err "Arvan TXT record creation failed."
  return 1
}

dns_arvan_rm() {
  fulldomain="$1"
  txtvalue="$2"
  _info "Using Arvan"
  Arvan_Token="${Arvan_Token:-$(_readaccountconf_mutable Arvan_Token)}"
  [ -n "$Arvan_Token" ] || { _err "Arvan_Token is not available."; return 1; }
  _get_root "$fulldomain" || { _err "Unable to find the Arvan root zone."; return 1; }

  page=1
  while true; do
    _arvan_rest GET "$_domain/dns-records" "?page=$page&per_page=100" || { _err "Could not list Arvan DNS records."; return 1; }
    if ! printf '%s' "$response" | jq -e '.data | type == "array"' >/dev/null 2>&1; then
      _err "Arvan returned an unexpected DNS-record response."
      return 1
    fi

    _record_id=$(printf '%s' "$response" | jq -r --arg name "$_sub_domain" --arg text "$txtvalue" '.data[]? | select((.type | ascii_downcase) == "txt" and .name == $name and .value.text == $text) | .id' | head -n 1)
    if [ -n "$_record_id" ] && [ "$_record_id" != "null" ]; then
      _arvan_rest DELETE "$_domain/dns-records/$_record_id" "" || { _err "Arvan TXT record deletion failed."; return 1; }
      _info "TXT record removed."
      return 0
    fi

    last_page=$(printf '%s' "$response" | jq -r '.meta.last_page // 1')
    case "$last_page" in *[!0-9]*|'') last_page=1 ;; esac
    [ "$page" -lt "$last_page" ] || break
    page=$((page + 1))
  done
  _info "TXT record was already absent."
  return 0
}

_get_root() {
  domain="$1"
  command -v jq >/dev/null 2>&1 || { _err "jq is required."; return 1; }
  i=2
  p=1
  while true; do
    h=$(printf '%s' "$domain" | cut -d . -f "$i"-100)
    [ -n "$h" ] || return 1
    page=1
    while true; do
      _arvan_rest GET "" "?page=$page&per_page=100" || return 1
      if ! printf '%s' "$response" | jq -e '.data | type == "array"' >/dev/null 2>&1; then
        _err "Arvan returned an unexpected domains response."
        return 1
      fi
      _domain_id=$(printf '%s' "$response" | jq -r --arg target "$h" '.data[]? | select(.domain == $target) | .id' | head -n 1)
      if [ -n "$_domain_id" ] && [ "$_domain_id" != "null" ]; then
        _sub_domain=$(printf '%s' "$domain" | cut -d . -f 1-"$p")
        _domain="$h"
        return 0
      fi
      last_page=$(printf '%s' "$response" | jq -r '.meta.last_page // 1')
      case "$last_page" in *[!0-9]*|'') last_page=1 ;; esac
      [ "$page" -lt "$last_page" ] || break
      page=$((page + 1))
    done
    p=$i
    i=$(_math "$i" + 1)
  done
}

_arvan_rest() {
  mtd="$1"
  ep="$2"
  data="${3-}"
  token_trimmed=$(printf '%s' "$Arvan_Token" | tr -d '"')
  case "$token_trimmed" in
    Apikey\ *|APIKEY\ *|apikey\ *) ;;
    *) token_trimmed="Apikey $token_trimmed" ;;
  esac
  export _H1="Authorization: $token_trimmed"
  export _H3="Accept: application/json"
  case "$mtd" in
    POST)
      export _H2="Content-Type: application/json"
      response="$(_post "$data" "$ARVAN_API_URL/$ep" "" "$mtd")" || return 1
      ;;
    DELETE)
      response="$(_post "" "$ARVAN_API_URL/$ep" "" "$mtd")" || return 1
      ;;
    GET)
      response="$(_get "$ARVAN_API_URL/$ep$data")" || return 1
      ;;
    *) _err "Unsupported Arvan HTTP method: $mtd"; return 1 ;;
  esac
  return 0
}
PLUGIN
}

get_access_key() {
  if [[ -z "${ARVAN_ACCESS_KEY:-}" ]]; then
    if [[ -r /dev/tty ]]; then
      read -r -s -p "Arvan access key: " ARVAN_ACCESS_KEY < /dev/tty
    else
      die "No interactive terminal is available. Set ARVAN_ACCESS_KEY securely."
    fi
    printf '\n'
  fi
  [[ -n "${ARVAN_ACCESS_KEY:-}" ]] || die "Arvan access key is required."
  [[ "$ARVAN_ACCESS_KEY" != *$'\n'* && "$ARVAN_ACCESS_KEY" != *$'\r'* ]] || die "Arvan access key must be a single line."
  export ARVAN_ACCESS_KEY
}

arvan_auth_header() {
  case "$ARVAN_ACCESS_KEY" in
    Apikey\ *|APIKEY\ *|apikey\ *) printf '%s' "$ARVAN_ACCESS_KEY" ;;
    *) printf 'Apikey %s' "$ARVAN_ACCESS_KEY" ;;
  esac
}

verify_arvan_access() {
  local result body status domain_found auth_header auth_file
  local page=1 last_page=1
  auth_header="$(arvan_auth_header)"
  auth_header="${auth_header//\\/\\\\}"
  auth_header="${auth_header//\"/\\\"}"
  auth_file="$(mktemp "/run/.arvancloud-letsencrypt-auth.XXXXXX")"
  chmod 600 "$auth_file"
  printf 'header = "Authorization: %s"\nheader = "Accept: application/json"\n' "$auth_header" > "$auth_file"

  while true; do
    if ! result="$(curl --config "$auth_file" --connect-timeout 10 --max-time 30 -sS -w $'\n%{http_code}' \
      "${ARVAN_API_URL}/?page=${page}&per_page=100")"; then
      rm -f "$auth_file"
      die "Could not connect to the ArvanCloud API."
    fi
    status="${result##*$'\n'}"
    body="${result%$'\n'*}"
    if [[ "$status" != "200" ]]; then
      rm -f "$auth_file"
      log "ArvanCloud API check failed (HTTP ${status})."
      printf '%s\n' "$body" | jq -c '{message: .message}' 2>/dev/null || true
      die "Check the access key and its DNS-zone permissions."
    fi
    if ! printf '%s' "$body" | jq -e '.data | type == "array"' >/dev/null 2>&1; then
      rm -f "$auth_file"
      die "ArvanCloud returned an unexpected domains response."
    fi
    domain_found="$(printf '%s' "$body" | jq -r --arg target "$DOMAIN" 'any(.data[]?; .domain == $target)')"
    if [[ "$domain_found" == "true" ]]; then
      rm -f "$auth_file"
      log "ArvanCloud API access verified for ${DOMAIN}."
      return 0
    fi
    last_page="$(printf '%s' "$body" | jq -r '.meta.last_page // 1')"
    [[ "$last_page" =~ ^[0-9]+$ ]] || last_page=1
    [[ "$page" -lt "$last_page" ]] || break
    page=$((page + 1))
  done
  rm -f "$auth_file"
  log "The ArvanCloud key can reach the API but cannot see the requested DNS zone."
  die "Grant the key access to ${DOMAIN}. The full zone list is intentionally not written to disk or logs."
}
install_cron_if_missing() {
  if ! crontab -l 2>/dev/null | grep -Eq 'acme\.sh.*--cron'; then
    log "Installing the acme.sh cron job"
    "$ACME_BIN" --install-cronjob
  else
    log "An acme.sh cron job already exists"
  fi
}

issue_and_install() {
  local issue_rc=0
  local debug_args=()
  local force_args=()
  local install_args=(--install-cert -d "$DOMAIN" --ecc \
    --key-file "${INSTALL_DIR}/privkey.pem" \
    --fullchain-file "${INSTALL_DIR}/fullchain.pem" \
    --cert-file "${INSTALL_DIR}/cert.pem" \
    --ca-file "${INSTALL_DIR}/chain.pem")

  [[ "$DEBUG" == "1" ]] && debug_args+=(--debug 2)
  [[ "$FORCE" == "1" ]] && force_args+=(--force)
  [[ -n "$RELOAD_CMD" ]] && install_args+=(--reloadcmd "$RELOAD_CMD")

  mkdir -p "$INSTALL_DIR"
  chmod 700 "$INSTALL_DIR"
  log "Requesting an ECC wildcard certificate for $DOMAIN"
  Arvan_Token="$ARVAN_ACCESS_KEY" "$ACME_BIN" --issue \
    --home "$ACME_HOME" \
    --dns dns_arvan \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --keylength ec-256 \
    --server letsencrypt \
    --dnssleep "$DNSSLEEP" \
    "${force_args[@]}" \
    "${debug_args[@]}" || issue_rc=$?

  if [[ "$issue_rc" -ne 0 && "$issue_rc" -ne 2 ]]; then
    die "Certificate issuance failed. Check ${LOG_DIR}/acme-issue.log."
  fi

  [[ -s "${ACME_HOME}/${DOMAIN}_ecc/fullchain.cer" ]] || die "The ACME certificate file was not created."
  log "Installing certificate files into $INSTALL_DIR"
  "$ACME_BIN" --home "$ACME_HOME" "${install_args[@]}"

  chmod 600 "${INSTALL_DIR}/privkey.pem"
  chmod 644 "${INSTALL_DIR}/cert.pem" "${INSTALL_DIR}/chain.pem" "${INSTALL_DIR}/fullchain.pem"
  log "Certificate installed successfully"
  openssl x509 -in "${INSTALL_DIR}/fullchain.pem" -noout -subject -issuer -dates -ext subjectAltName
}

run_worker() {
  issue_and_install >>"${LOG_DIR}/acme-issue.log" 2>&1
  log "Completed certificate job for $DOMAIN" >>"${LOG_DIR}/acme-issue.log"
}

install_dependencies
install_acme
install_dns_plugin
install_cron_if_missing
get_access_key
verify_arvan_access

if [[ "$BACKGROUND" == "1" ]]; then
  log "Starting the certificate job in the background"
  trap '' HUP
  run_worker < /dev/null &
  worker_pid="$!"
  disown "$worker_pid" 2>/dev/null || true
  log "Started PID $worker_pid"
  log "Follow progress with: tail -f ${LOG_DIR}/acme-issue.log"
else
  run_worker
fi

log "Repository script version $SCRIPT_VERSION finished setup"

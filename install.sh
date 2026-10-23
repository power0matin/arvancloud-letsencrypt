#!/usr/bin/env bash
set -Eeuo pipefail

readonly RAW_BASE="https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main"
readonly MENU_URL="${RAW_BASE}/menu.sh"
readonly CORE_URL="${RAW_BASE}/core.sh"
readonly ACME_HOME="/root/.acme.sh"
readonly ACME_BIN="${ACME_HOME}/acme.sh"
readonly LOG_DIR="/var/log/arvancloud-letsencrypt"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_CYAN=""; C_GREEN=""; C_RED=""
fi

die() { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }
ok() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$C_CYAN" "$C_RESET" "$*" >&2; }

usage() {
  cat <<'EOF'
ArvanCloud Let's Encrypt — wildcard certificate manager

Interactive menu:
  curl -fsSL https://raw.githubusercontent.com/power0matin/arvancloud-letsencrypt/main/install.sh | sudo bash

Issue and install a certificate:
  sudo bash install.sh --domain example.com [options]

CLI actions:
  --menu                    Open the interactive menu
  --list                    List certificates registered with acme.sh
  --info DOMAIN             Inspect a certificate in the default output paths
  --renew                   Run the normal acme.sh renewal check
  --logs                    Show recent installer and issuance logs
  --check                   Check local dependencies and renewal setup
  --help                    Show this help

Issue options:
  --domain DOMAIN           Base domain managed by ArvanCloud DNS
  --email EMAIL             ACME account email
  --install-dir DIR         Certificate output directory
  --reload-cmd COMMAND      Command run after successful installation
  --x-ui                    Use /root/cert/DOMAIN and x-ui restart
  --background              Continue issuance after SSH disconnect
  --force                   Force a new certificate order
  --dns-sleep SECONDS       DNS propagation wait (default: 180)
  --debug                   Enable verbose acme.sh output
EOF
}

require_root() {
  [[ "$(id -u)" == "0" ]] || die "Run this command as root, for example with sudo."
}

validate_domain() {
  local label
  local -a labels=()
  DOMAIN="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')"
  [[ -n "$DOMAIN" && "${#DOMAIN}" -le 253 && "$DOMAIN" == *.* ]] || die "Provide a fully-qualified domain such as example.com."
  [[ "$DOMAIN" != *'*'* && "$DOMAIN" != *'/'* && "$DOMAIN" != *' '* ]] || die "Use the base domain only, without wildcard or path."
  IFS='.' read -r -a labels <<< "$DOMAIN"
  for label in "${labels[@]}"; do
    [[ "${#label}" -ge 1 && "${#label}" -le 63 ]] || die "Invalid DNS label in domain."
    [[ "$label" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || die "Invalid DNS label in domain."
  done
}

run_list() {
  [[ -x "$ACME_BIN" ]] || die "acme.sh is not installed at ${ACME_BIN}."
  "$ACME_BIN" --home "$ACME_HOME" --list
}

run_info() {
  local domain="$1" file candidate
  validate_domain "$domain"
  file=""
  for candidate in "/etc/ssl/acme/${DOMAIN}/fullchain.pem" "/root/cert/${DOMAIN}/fullchain.pem"; do
    if [[ -s "$candidate" ]]; then file="$candidate"; break; fi
  done
  [[ -n "$file" ]] || die "No certificate found in the default output paths for ${DOMAIN}."
  printf 'Certificate file: %s\n' "$file"
  openssl x509 -in "$file" -noout -subject -issuer -serial -dates -ext subjectAltName
  printf '\nHostname verification:\n'
  openssl x509 -in "$file" -noout -checkhost "$DOMAIN"
  openssl x509 -in "$file" -noout -checkhost "probe.$DOMAIN"
}

run_renew() {
  [[ -x "$ACME_BIN" ]] || die "acme.sh is not installed at ${ACME_BIN}."
  "$ACME_BIN" --home "$ACME_HOME" --cron
}

run_logs() {
  local found=0 file
  for file in "$LOG_DIR/install.log" "$LOG_DIR/acme-issue.log"; do
    if [[ -f "$file" ]]; then
      found=1
      printf '\n--- %s (last 80 lines) ---\n' "$file"
      tail -n 80 "$file"
    fi
  done
  [[ "$found" == "1" ]] || warn "No logs have been created yet."
}

run_check() {
  local tool
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf 'System: %s\n' "${PRETTY_NAME:-unknown}"
  fi
  for tool in curl openssl jq crontab flock; do
    if command -v "$tool" >/dev/null 2>&1; then ok "$tool found"; else warn "$tool missing"; fi
  done
  if [[ -x "$ACME_BIN" ]]; then ok "acme.sh installed"; else warn "acme.sh not installed"; fi
  if [[ -f "$ACME_HOME/dnsapi/dns_arvan.sh" ]]; then ok "Arvan DNS plugin installed"; else warn "Arvan DNS plugin not installed"; fi
  if crontab -l 2>/dev/null | grep -Eq 'acme\.sh.*--cron'; then ok "acme.sh renewal job found"; else warn "acme.sh renewal job not found"; fi
  printf '\nLogs: %s\nThis check does not contact ArvanCloud or change the server.\n' "$LOG_DIR"
}

if [[ "$#" -eq 0 || "$1" == "--menu" ]]; then
  [[ "$#" -eq 0 || "$#" -eq 1 ]] || die "--menu does not accept additional arguments."
  require_root
  [[ -r /dev/tty && -w /dev/tty ]] || die "An interactive terminal is required. Use --help for CLI usage."
  curl -fsSL "$MENU_URL" | bash
  exit $?
fi

case "$1" in
  --help|-h) usage; exit 0 ;;
  --list) [[ "$#" -eq 1 ]] || die "--list takes no arguments."; require_root; run_list; exit $? ;;
  --info) [[ "$#" -eq 2 ]] || die "--info requires a domain."; require_root; run_info "$2"; exit $? ;;
  --renew) [[ "$#" -eq 1 ]] || die "--renew takes no arguments."; require_root; run_renew; exit $? ;;
  --logs) [[ "$#" -eq 1 ]] || die "--logs takes no arguments."; require_root; run_logs; exit $? ;;
  --check) [[ "$#" -eq 1 ]] || die "--check takes no arguments."; require_root; run_check; exit $? ;;
esac

require_root
curl -fsSL "$CORE_URL" | bash -s -- "$@"

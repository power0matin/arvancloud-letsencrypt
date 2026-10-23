#!/usr/bin/env bash
set -Eeuo pipefail

readonly REPOSITORY="power0matin/arvancloud-letsencrypt"
readonly RAW_BASE="https://raw.githubusercontent.com/${REPOSITORY}/main"
readonly INSTALL_URL="${RAW_BASE}/install.sh"
readonly ACME_HOME="/root/.acme.sh"
readonly ACME_BIN="${ACME_HOME}/acme.sh"
readonly LOG_DIR="/var/log/arvancloud-letsencrypt"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_CYAN=""; C_GREEN=""; C_RED=""; C_DIM=""; C_BOLD=""
fi

die() { printf '%s[ERROR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }
warn() { printf '%s[WARN]%s %s\n' "$C_CYAN" "$C_RESET" "$*" >&2; }
ok() { printf '%s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }

[[ "$(id -u)" == "0" ]] || die "Run the menu as root, for example: curl .../install.sh | sudo bash"
[[ -r /dev/tty && -w /dev/tty ]] || die "An interactive terminal is required. Run install.sh --help for CLI usage."

prompt_line() {
  local prompt="$1" var_name="$2" default_value="${3:-}" value=""
  printf '%s' "$prompt" > /dev/tty
  IFS= read -r value < /dev/tty || die "Could not read terminal input."
  printf -v "$var_name" '%s' "${value:-$default_value}"
}

pause_menu() {
  local _unused=""
  printf '\nPress Enter to return to the menu...' > /dev/tty
  IFS= read -r _unused < /dev/tty || true
}

show_banner() {
  printf '\n%s%s  ARVANCLOUD / LET'\''S ENCRYPT%s\n' "$C_BOLD" "$C_CYAN" "$C_RESET"
  printf '%s  Wildcard certificate manager%s\n\n' "$C_DIM" "$C_RESET"
}

issue_flow() {
  local domain email answer output_dir reload_cmd dns_sleep
  local -a args=()
  prompt_line "Base domain (example.com): " domain
  [[ -n "$domain" ]] || { warn "A domain is required."; return 0; }
  prompt_line "ACME account email (optional): " email
  args+=(--domain "$domain")
  if [[ -n "$email" ]]; then args+=(--email "$email"); fi

  prompt_line "Use x-ui paths and restart command? [y/N]: " answer "n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    args+=(--x-ui)
  else
    prompt_line "Certificate output directory [/etc/ssl/acme/${domain}]: " output_dir "/etc/ssl/acme/${domain}"
    if [[ -n "$output_dir" ]]; then args+=(--install-dir "$output_dir"); fi
    prompt_line "Optional reload command (blank for none): " reload_cmd
    if [[ -n "$reload_cmd" ]]; then args+=(--reload-cmd "$reload_cmd"); fi
  fi

  prompt_line "DNS propagation wait in seconds [180]: " dns_sleep "180"
  if [[ -n "$dns_sleep" ]]; then args+=(--dns-sleep "$dns_sleep"); fi
  prompt_line "Continue in background after SSH disconnect? [y/N]: " answer "n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then args+=(--background); fi
  prompt_line "Force a fresh certificate order? [y/N]: " answer "n"
  if [[ "$answer" =~ ^[Yy]$ ]]; then args+=(--force); fi

  printf '\nThe installer will ask for the ArvanCloud access key in a hidden prompt.\n\n'
  if ! curl -fsSL "$INSTALL_URL" | bash -s -- "${args[@]}"; then
    warn "The install command failed. Check the output and network connection."
  fi
}

run_list() {
  [[ -x "$ACME_BIN" ]] || { warn "acme.sh is not installed at ${ACME_BIN}."; return 0; }
  "$ACME_BIN" --home "$ACME_HOME" --list
}

run_info() {
  local domain file candidate
  prompt_line "Base domain to inspect: " domain
  domain="$(printf '%s' "$domain" | tr '[:upper:]' '[:lower:]' | sed 's/\.$//')"
  [[ "$domain" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]] || { warn "Invalid domain."; return 0; }
  file=""
  for candidate in "/etc/ssl/acme/${domain}/fullchain.pem" "/root/cert/${domain}/fullchain.pem"; do
    if [[ -s "$candidate" ]]; then file="$candidate"; break; fi
  done
  [[ -n "$file" ]] || { warn "No certificate found in the default output paths."; return 0; }
  printf 'Certificate file: %s\n' "$file"
  openssl x509 -in "$file" -noout -subject -issuer -serial -dates -ext subjectAltName
  printf '\nHostname verification:\n'
  openssl x509 -in "$file" -noout -checkhost "$domain"
  openssl x509 -in "$file" -noout -checkhost "probe.$domain"
}

run_renew() {
  [[ -x "$ACME_BIN" ]] || { warn "acme.sh is not installed."; return 0; }
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
  printf 'System: '
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s\n' "${PRETTY_NAME:-unknown}"
  else
    printf 'unknown\n'
  fi
  for tool in curl openssl jq crontab flock; do
    if command -v "$tool" >/dev/null 2>&1; then ok "$tool found"; else warn "$tool missing"; fi
  done
  if [[ -x "$ACME_BIN" ]]; then ok "acme.sh installed"; else warn "acme.sh not installed"; fi
  if [[ -f "$ACME_HOME/dnsapi/dns_arvan.sh" ]]; then ok "Arvan DNS plugin installed"; else warn "Arvan DNS plugin not installed"; fi
  if crontab -l 2>/dev/null | grep -Eq 'acme\.sh.*--cron'; then ok "acme.sh renewal job found"; else warn "acme.sh renewal job not found"; fi
  printf '\nLogs: %s\nThis check does not contact ArvanCloud or change the server.\n' "$LOG_DIR"
}

while true; do
  show_banner
  printf '  %s1%s  Issue and install a wildcard certificate\n' "$C_CYAN" "$C_RESET"
  printf '  %s2%s  List registered certificates\n' "$C_CYAN" "$C_RESET"
  printf '  %s3%s  Inspect an installed certificate\n' "$C_CYAN" "$C_RESET"
  printf '  %s4%s  Run the normal renewal check\n' "$C_CYAN" "$C_RESET"
  printf '  %s5%s  View recent logs\n' "$C_CYAN" "$C_RESET"
  printf '  %s6%s  Check local installation\n' "$C_CYAN" "$C_RESET"
  printf '  %s0%s  Exit\n\n' "$C_CYAN" "$C_RESET"
  printf 'Select an option: ' > /dev/tty
  choice=""
  IFS= read -r choice < /dev/tty || die "Could not read menu selection."
  case "$choice" in
    1) issue_flow; pause_menu ;;
    2) run_list; pause_menu ;;
    3) run_info; pause_menu ;;
    4) run_renew; pause_menu ;;
    5) run_logs; pause_menu ;;
    6) run_check; pause_menu ;;
    0|q|Q) printf 'Goodbye.\n'; exit 0 ;;
    *) warn "Choose one of the displayed options."; pause_menu ;;
  esac
done

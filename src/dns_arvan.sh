#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-or-later

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
      _arvan_url="$ARVAN_API_URL/$ep$data"
      _arvan_attempt=1
      while :; do
        response="$(_get "$_arvan_url")"
        _arvan_get_ret=$?
        _arvan_http_status=""
        if [ -n "${HTTP_HEADER:-}" ] && [ -f "$HTTP_HEADER" ]; then
          _arvan_http_status="$(awk '/^HTTP[\/ ]/ { status=$2 } END { print status }' "$HTTP_HEADER")"
        fi

        _arvan_retryable=0
        if [ "$_arvan_get_ret" -ne 0 ]; then
          _arvan_retryable=1
        else
          case "$_arvan_http_status" in
            429|5[0-9][0-9]) _arvan_retryable=1 ;;
          esac
        fi

        [ "$_arvan_retryable" -eq 0 ] && break
        if [ "$_arvan_attempt" -ge 3 ]; then
          _err "ArvanCloud GET request failed after $_arvan_attempt attempts (HTTP status ${_arvan_http_status:-unknown})."
          return 1
        fi

        _arvan_delay="$_arvan_attempt"
        _info "Temporary ArvanCloud GET failure (HTTP status ${_arvan_http_status:-unknown}); retrying in ${_arvan_delay}s."
        _sleep "$_arvan_delay"
        _arvan_attempt=$((_arvan_attempt + 1))
      done
      ;;
    *) _err "Unsupported Arvan HTTP method: $mtd"; return 1 ;;
  esac
  return 0
}

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: validate-registry-access.sh <provider> <registry-url> [token-env-var]

provider: shadcnblocks | aceternity | shadcn-darkmatter

The optional token-env-var is the name of an environment variable containing
the API key/token. The token value is never printed.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 2
fi

provider="$1"
url="$2"
token_env="${3:-}"

case "$provider" in
  shadcnblocks | aceternity | shadcn-darkmatter) ;;
  *)
    echo "error: unsupported provider '$provider'" >&2
    usage
    exit 2
    ;;
esac

if [[ "$provider" != "shadcn-darkmatter" && -z "$token_env" ]]; then
  echo "error: $provider requires a token env var name" >&2
  exit 1
fi

headers=()
if [[ -n "$token_env" ]]; then
  token="${!token_env:-}"
  if [[ -z "$token" ]]; then
    echo "error: $token_env is not set" >&2
    exit 1
  fi
  headers=(-H "Authorization: Bearer $token")
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

status="$(
	curl -sS -L -o "$tmp" -w '%{http_code}' \
		--connect-timeout 10 \
		--max-time 30 \
		"${headers[@]}" \
		"$url"
)"

case "$status" in
  2* | 3*)
    echo "ok: $provider registry reachable ($status)"
    ;;
  401 | 403)
    echo "error: $provider registry rejected credentials ($status)" >&2
    exit 1
    ;;
  *)
    echo "error: $provider registry fetch failed ($status)" >&2
    exit 1
    ;;
esac

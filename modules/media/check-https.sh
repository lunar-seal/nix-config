#!/usr/bin/env bash
# Run from the LAN: bash modules/media/check-https.sh /path/to/kodi-password
set -euo pipefail
password_file=${1:?Pass the Kodi password file}
address=${2:-192.168.178.117}
url=https://jester.ff15.eu:8443/jsonrpc
curl_args=(--silent --show-error --connect-timeout 3 --max-time 10
  --resolve "jester.ff15.eu:8443:$address")

test "$(curl "${curl_args[@]}" -o /dev/null -w '%{http_code}' "$url")" = 401
password=$(tr -d '\r\n' < "$password_file")
[[ $password =~ ^[0-9a-f]{64}$ ]]
printf 'user = "kodi:%s"\n' "$password" |
  curl "${curl_args[@]}" --fail --config - \
    -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"JSONRPC.Ping","id":1}' "$url" |
  jq -e '.result == "pong"' >/dev/null

if curl --silent --connect-timeout 3 --max-time 5 "http://$address:8080/jsonrpc" >/dev/null; then
  echo 'FAIL: old HTTP endpoint is still reachable' >&2
  exit 1
fi
if curl --silent --connect-timeout 3 --max-time 5 "http://$address:8443/jsonrpc" >/dev/null; then
  echo 'FAIL: HTTPS port accepts plaintext HTTP' >&2
  exit 1
fi
echo 'PASS: trusted HTTPS, authentication required, new password works, HTTP unavailable'

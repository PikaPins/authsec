#!/usr/bin/env bash
set -euo pipefail

# Fetch script for https://wechat.doonsec.com/api/v1/es/
# Provide credentials via GitHub Secrets (recommended):
#   DOONSEC_CSRFTOKEN (required)
#   DOONSEC_COOKIE    (optional)
#
# Optional env:
#   KEYWORD (default "Oauth")
#   ACCOUNT_BIZ (default "")
#   DATE_DATA (default "all")
#   OUT_DIR (default "artifacts")

: "${DOONSEC_CSRFTOKEN:?DOONSEC_CSRFTOKEN must be set (from GitHub Secrets)}"

KEYWORD="${KEYWORD:-Oauth}"
ACCOUNT_BIZ="${ACCOUNT_BIZ:-}"
DATE_DATA="${DATE_DATA:-all}"
OUT_DIR="${OUT_DIR:-artifacts}"

mkdir -p "$OUT_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="$OUT_DIR/es_response_${TIMESTAMP}.json"

# URL-encode helper using python
urlenc() {
  python3 - <<'PY'
import sys,urllib.parse
s = sys.stdin.read().strip()
print(urllib.parse.quote(s, safe=''))
PY
}

BODY="keyword=$(printf '%s' \"$KEYWORD\" | urlenc)&account__biz=$(printf '%s' \"$ACCOUNT_BIZ\" | urlenc)&date_data=$(printf '%s' \"$DATE_DATA\" | urlenc)"

# Build cookie header if provided
COOKIE_HEADER=()
if [[ -n "${DOONSEC_COOKIE:-}" ]]; then
  COOKIE_HEADER=(-H \"Cookie: ${DOONSEC_COOKIE}\")
fi

# Perform request with curl using HTTP/2
curl --http2 -sS -X POST \"https://wechat.doonsec.com/api/v1/es/\" \
  -H \"Host: wechat.doonsec.com\" \
  -H \"User-Agent: QtWebEngine/5.12.5 Chrome/69.0.3497.128 Safari/537.36 QtWebEngine/Lexus/5.12.5\" \
  -H \"Accept: */*\" \
  -H \"Accept-Language: zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2\" \
  -H \"Accept-Encoding: gzip, deflate, br\" \
  -H \"Content-Type: application/x-www-form-urlencoded; charset=UTF-8\" \
  -H \"X-Csrftoken: ${DOONSEC_CSRFTOKEN}\" \
  -H \"X-Requested-With: XMLHttpRequest\" \
  -H \"Origin: https://wechat.doonsec.com\" \
  -H \"Sec-Fetch-Dest: empty\" \
  -H \"Sec-Fetch-Mode: cors\" \
  -H \"Sec-Fetch-Site: same-origin\" \
  \"${COOKIE_HEADER[@]}\" \
  --data \"$BODY\" \
  -o \"$OUT_FILE\"

echo \"Saved response to $OUT_FILE\"

# Try to parse the response into structured resource file
PARSED_OUT="${OUT_DIR}/es_parsed_${TIMESTAMP}.json"
python3 scripts/parse_es.py \"$OUT_FILE\" \"$PARSED_OUT\" || echo \"Parsing failed or returned no structured resources\"
if [[ -f \"$PARSED_OUT\" ]]; then
  echo \"Parsed resources saved to $PARSED_OUT\"
fi

exit 0

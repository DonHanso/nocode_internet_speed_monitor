#!/usr/bin/env bash
set -euo pipefail

# 1) Projekt-Root ermitteln (Annahme: Skript liegt in scripts/)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 2) .env laden
ENV_FILE="$ROOT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "ERROR: .env nicht gefunden unter $ENV_FILE" >&2
  exit 1
fi

# 3) Erwartete Variablen prüfen
: "${INFLUXDB_PORT:?INFLUXDB_PORT muss gesetzt sein}"
: "${INFLUXDB_INIT_ORG:?INFLUXDB_INIT_ORG muss gesetzt sein}"
: "${INFLUXDB_INIT_BUCKET:?INFLUXDB_INIT_BUCKET muss gesetzt sein}"
: "${INFLUXDB_INIT_ADMIN_TOKEN:?INFLUXDB_INIT_ADMIN_TOKEN muss gesetzt sein}"

# 4) Debug-Ausgabe
echo "DEBUG: InfluxDB-URL = http://localhost:${INFLUXDB_PORT}"
echo "DEBUG: Org         = $INFLUXDB_INIT_ORG"
echo "DEBUG: Bucket      = $INFLUXDB_INIT_BUCKET"
echo "DEBUG: Token       = ${INFLUXDB_INIT_ADMIN_TOKEN:0:8}…"

# 5) Speedtest ausführen
echo "DEBUG: Running speedtest…"
RESULT=$(speedtest --accept-license --accept-gdpr -f json)
echo "DEBUG: Raw result = $RESULT"

# 6) JSON parsen
DOWNLOAD=$(jq -r '.download.bandwidth' <<<"$RESULT")
UPLOAD=$(jq -r '.upload.bandwidth'   <<<"$RESULT")
PING=$(jq -r '.ping.latency'         <<<"$RESULT")
echo "DEBUG: Parsed – download=${DOWNLOAD}B/s, upload=${UPLOAD}B/s, ping=${PING}ms"

# 7) Timestamp und Umrechnung
TS=$(date +%s%N)
DL_MBIT=$(awk "BEGIN {printf \"%.2f\", $DOWNLOAD*8/1000000}")
UL_MBIT=$(awk "BEGIN {printf \"%.2f\", $UPLOAD*8/1000000}")
echo "DEBUG: Converted – download=${DL_MBIT}Mbit/s, upload=${UL_MBIT}Mbit/s, ts=${TS}"

# 8) Line Protocol bauen
HOST=$(hostname -s)
LINE="internet_speed,host=${HOST} download=${DL_MBIT},upload=${UL_MBIT},ping=${PING} ${TS}"
echo "DEBUG: Line Protocol = $LINE"

# 9) POST an InfluxDB
WRITE_URL="http://localhost:${INFLUXDB_PORT}/api/v2/write?bucket=${INFLUXDB_INIT_BUCKET}&org=${INFLUXDB_INIT_ORG}&precision=ns"
echo "DEBUG: POST to $WRITE_URL"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -XPOST "$WRITE_URL" \
  -H "Authorization: Token ${INFLUXDB_INIT_ADMIN_TOKEN}" \
  -H "Content-Type: text/plain; charset=utf-8" \
  --data-binary "$LINE")

echo "DEBUG: HTTP status = $HTTP_CODE"
if [ "$HTTP_CODE" -ne 204 ]; then
  echo "ERROR: InfluxDB write failed with status $HTTP_CODE" >&2
  exit 1
fi

echo "DEBUG: Write successful."

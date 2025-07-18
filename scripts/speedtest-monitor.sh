#!/usr/bin/env bash
set -euo pipefail

# Skript-Root (angenommen scripts/ liegt im Projekt-Root)
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# .env laden
ENV_FILE="$ROOT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
else
  echo "ERROR: .env nicht gefunden unter $ENV_FILE" >&2
  exit 1
fi

# Erforderliche Variablen prüfen
: "${INFLUXDB_PORT:?INFLUXDB_PORT muss gesetzt sein}"
: "${INFLUXDB_INIT_ORG:?INFLUXDB_INIT_ORG muss gesetzt sein}"
: "${INFLUXDB_INIT_BUCKET:?INFLUXDB_INIT_BUCKET muss gesetzt sein}"
: "${INFLUXDB_INIT_ADMIN_TOKEN:?INFLUXDB_INIT_ADMIN_TOKEN muss gesetzt sein}"

# Speedtest ausführen und JSON-Ergebnis holen
RESULT=$(speedtest --accept-license --accept-gdpr -f json)

# Werte parsen
DOWNLOAD=$(jq -r '.download.bandwidth'   <<<"$RESULT")
UPLOAD=$(jq -r '.upload.bandwidth'       <<<"$RESULT")
PING=$(jq -r '.ping.latency'             <<<"$RESULT")

# Timestamp und Umrechnung in Mbit/s
TS=$(date +%s%N)
DL_MBIT=$(awk "BEGIN {printf \"%.2f\", $DOWNLOAD*8/1000000}")
UL_MBIT=$(awk "BEGIN {printf \"%.2f\", $UPLOAD*8/1000000}")

# Line Protocol bauen
HOST=$(hostname -s)
LINE="internet_speed,host=${HOST} download=${DL_MBIT},upload=${UL_MBIT},ping=${PING} ${TS}"

# InfluxDB schreiben
WRITE_URL="http://localhost:${INFLUXDB_PORT}/api/v2/write?bucket=${INFLUXDB_INIT_BUCKET}&org=${INFLUXDB_INIT_ORG}&precision=ns"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$WRITE_URL" \
  -H "Authorization: Token ${INFLUXDB_INIT_ADMIN_TOKEN}" \
  -H "Content-Type: text/plain; charset=utf-8" \
  --data-binary "$LINE")

if [ "$HTTP_CODE" -ne 204 ]; then
  echo "ERROR: InfluxDB write failed with HTTP status $HTTP_CODE" >&2
  exit 1
fi

exit 0

#!/usr/bin/env bash
set -euo pipefail

# Load .env if available
[ -f /etc/internet_speed/.env ] && source /etc/internet_speed/.env

INFLUX_URL=${INFLUX_URL:-http://localhost:${INFLUXDB_PORT:-8086}}
HOST=$(hostname)

RESULT=$(speedtest --accept-license --accept-gdpr -f json)
TS=$(date +%s%N)
DOWNLOAD=$(jq -r '.download.bandwidth' <<< "$RESULT")
UPLOAD=$(jq -r '.upload.bandwidth' <<< "$RESULT")
PING=$(jq -r '.ping.latency' <<< "$RESULT")

# Convert to Mbit/s
DL_MBIT=$(echo "scale=2; $DOWNLOAD * 8 / 1000000" | bc)
UL_MBIT=$(echo "scale=2; $UPLOAD * 8 / 1000000" | bc)

LINE="internet_speed,host=$HOST download=$DL_MBIT,upload=$UL_MBIT,ping=$PING $TS"

curl -s -XPOST "$INFLUX_URL/write?db=${INFLUXDB_INIT_BUCKET:-internet_speed}" \
     --data-binary "$LINE" > /dev/null
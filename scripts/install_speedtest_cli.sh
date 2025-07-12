#!/usr/bin/env bash
set -euo pipefail

# Variables
VERSION=${SPEEDTEST_CLI_VERSION:-1.2.0}
ARCH=${SPEEDTEST_CLI_ARCH:-linux-x86_64}
URL="https://install.speedtest.net/app/cli/ookla-speedtest-${VERSION}-${ARCH}.tgz"
TMP_TGZ="/tmp/speedtest.tgz"

# Download
curl -fsSL "$URL" -o "$TMP_TGZ"

# Extract
tar -xzf "$TMP_TGZ" -C /tmp/

# Install binary
sudo mv /tmp/speedtest /usr/local/bin/
sudo chmod +x /usr/local/bin/speedtest

# Cleanup
rm -f "$TMP_TGZ"

echo "Ookla Speedtest CLI $VERSION installed successfully."
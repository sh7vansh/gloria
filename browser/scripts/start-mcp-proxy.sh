#!/bin/bash
# Start MCP Proxy to expose Chrome Bridge remotely

set -e

export PATH="/home/gloria/.local/bin:${PATH}"

MCP_PORT="${GLORIA_MCP_PORT:-8787}"

# Wait for Chromium and Chrome Bridge to be available
echo "[MCP Proxy] Waiting for Chromium to start..."
sleep 15

# Check if Chrome Bridge native host socket exists
for i in $(seq 1 60); do
    if [ -S /tmp/antigravity_chrome_bridge.sock ]; then
        echo "[MCP Proxy] Chrome Bridge native host socket detected."
        break
    fi
    if [ $i -eq 60 ]; then
        echo "[MCP Proxy] WARNING: Chrome Bridge socket not found after 60s. Starting MCP proxy anyway..."
    fi
    sleep 2
done

echo "[MCP Proxy] Starting on port ${MCP_PORT}..."
exec mcp-proxy \
    --host 0.0.0.0 \
    --port "${MCP_PORT}" \
    --stateless \
    -- \
    antigravity-chrome-bridge mcp

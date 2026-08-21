#!/bin/bash
# Start MCP Proxy to expose Chrome Bridge remotely

set -e

export PATH="/home/gloria/.local/bin:${PATH}"

MCP_PORT="${GLORIA_MCP_PORT:-8787}"

echo "[MCP Proxy] Starting MCP proxy on port ${MCP_PORT}..."
exec mcp-proxy \
    --host 0.0.0.0 \
    --port "${MCP_PORT}" \
    --allow-origin='*' \
    --stateless \
    -- \
    antigravity-chrome-bridge mcp

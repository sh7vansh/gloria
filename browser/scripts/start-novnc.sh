#!/bin/bash
set -e

WEB_PORT="${GLORIA_WEB_PORT:-8080}"
VNC_PORT="${GLORIA_VNC_PORT:-5901}"

echo "[noVNC] Waiting for VNC server on port ${VNC_PORT}..."
for i in $(seq 1 30); do
    if ss -tln | grep -q ":${VNC_PORT}"; then
        break
    fi
    sleep 1
done

echo "[noVNC] Starting zero-authentication HTML5 Web Desktop on port ${WEB_PORT}..."
exec websockify \
    --web /usr/share/novnc/ \
    "${WEB_PORT}" \
    "localhost:${VNC_PORT}"

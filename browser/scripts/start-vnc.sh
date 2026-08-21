#!/bin/bash
# Start TigerVNC server attached to the Xvfb display

set -e

DISPLAY_NUM="${DISPLAY:-:1}"
VNC_PORT="${GLORIA_VNC_PORT:-5901}"
VNC_GEOMETRY="${GLORIA_SCREEN_WIDTH:-1920}x${GLORIA_SCREEN_HEIGHT:-1080}"

# Wait for X server to be ready
echo "[VNC] Waiting for X server on ${DISPLAY_NUM}..."
for i in $(seq 1 30); do
    if xdpyinfo -display "${DISPLAY_NUM}" >/dev/null 2>&1; then
        echo "[VNC] X server is ready."
        break
    fi
    if [ $i -eq 30 ]; then
        echo "[VNC] ERROR: X server did not start in time."
        exit 1
    fi
    sleep 1
done

# Kill any existing VNC server on this display
vncserver -kill "${DISPLAY_NUM}" 2>/dev/null || true

# Remove stale lock files
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# Start x0vncserver to attach to the existing Xvfb display
# This shares the SAME display rather than creating a new one
exec x0vncserver \
    -display "${DISPLAY_NUM}" \
    -rfbport "${VNC_PORT}" \
    -PasswordFile "${HOME}/.vnc/passwd" \
    -rfbunixpath "" \
    -AcceptKeyEvents=on \
    -AcceptPointerEvents=on \
    -AcceptSetDesktopSize=on \
    -MaxProcessorUsage=90

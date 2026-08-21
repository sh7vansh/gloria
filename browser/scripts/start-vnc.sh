#!/bin/bash
set -e

DISPLAY_NUM="${DISPLAY:-:1}"
VNC_PORT="${GLORIA_VNC_PORT:-5901}"

echo "[VNC] Waiting for X server on ${DISPLAY_NUM}..."

for i in $(seq 1 30); do
    if xdpyinfo -display "${DISPLAY_NUM}" >/dev/null 2>&1; then
        echo "[VNC] X server is ready."
        break
    fi

    if [ "$i" -eq 30 ]; then
        echo "[VNC] ERROR: X server did not start in time."
        exit 1
    fi

    sleep 1
done

exec x0tigervncserver \
    -fg \
    -display "${DISPLAY_NUM}" \
    -rfbport "${VNC_PORT}" \
    -SecurityTypes None \
    --I-KNOW-THIS-IS-INSECURE \
    -AcceptKeyEvents=true \
    -AcceptPointerEvents=true \
    -AcceptSetDesktopSize=true \
    -MaxProcessorUsage=90

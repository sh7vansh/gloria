#!/usr/bin/env bash
set -e

DATA_DIR="${GLORIA_DATA:-/data}"
PROFILE_DIR="${DATA_DIR}/chromium/profile"
DOWNLOAD_DIR="${DATA_DIR}/downloads"

# Wait for X server and XFCE to be ready
echo "[Chromium] Waiting for desktop environment..."
for i in $(seq 1 60); do
    if xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

sleep 5

mkdir -p "${PROFILE_DIR}" "${DOWNLOAD_DIR}"

EXTENSION_DIR="${HOME}/.chrome-bridge/extension"
UBLOCK_DIR="/opt/extensions/ublock-origin-lite"

LOAD_EXTENSIONS="${EXTENSION_DIR}"
if [ -d "${UBLOCK_DIR}" ] && [ -f "${UBLOCK_DIR}/manifest.json" ]; then
    LOAD_EXTENSIONS="${LOAD_EXTENSIONS},${UBLOCK_DIR}"
    echo "[Chromium] Including uBlock Origin Lite from ${UBLOCK_DIR}"
fi

CHROMIUM_FLAGS=(
    --user-data-dir="${PROFILE_DIR}"
    --load-extension="${LOAD_EXTENSIONS}"
    --disable-extensions-except="${LOAD_EXTENSIONS}"
    --no-first-run
    --no-default-browser-check
    --disable-background-mode
    --disable-gpu-sandbox
    --disable-dev-shm-usage
    --no-sandbox
    --disable-setuid-sandbox
    --start-maximized
    --download-default-directory="${DOWNLOAD_DIR}"
    --remote-debugging-port=9222
    --enable-zero-copy
    --enable-features=WebRTCPipeWireCapturer
)

echo "[Chromium] Starting with persistent profile at ${PROFILE_DIR} and extensions at ${LOAD_EXTENSIONS}"

BROWSER_BIN="chromium"
if ! command -v "$BROWSER_BIN" >/dev/null 2>&1; then
    if command -v chromium-browser >/dev/null 2>&1; then
        BROWSER_BIN="chromium-browser"
    elif command -v google-chrome >/dev/null 2>&1; then
        BROWSER_BIN="google-chrome"
    fi
fi

exec "$BROWSER_BIN" "${CHROMIUM_FLAGS[@]}" "about:blank"

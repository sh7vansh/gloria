#!/bin/bash
# Start Chromium with persistent profile and Chrome Bridge extension

set -e

DATA_DIR="${GLORIA_DATA:-/data}"
PROFILE_DIR="${DATA_DIR}/chromium/profile"
DOWNLOAD_DIR="${DATA_DIR}/downloads"
EXTENSION_DIR="${HOME}/.chrome-bridge/extension"

# Wait for X server and XFCE to be ready
echo "[Chromium] Waiting for desktop environment..."
for i in $(seq 1 60); do
    if xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Give XFCE a moment to fully initialize
sleep 5

# Build Chromium flags
CHROMIUM_FLAGS=(
    --user-data-dir="${PROFILE_DIR}"
    --no-first-run
    --no-default-browser-check
    --disable-background-mode
    --disable-gpu-sandbox
    --disable-software-rasterizer
    --disable-dev-shm-usage
    --no-sandbox
    --disable-setuid-sandbox
    --start-maximized
    --download-default-directory="${DOWNLOAD_DIR}"
    --enable-features=WebRTCPipeWireCapturer
)

# Load Chrome Bridge extension if available
if [ -d "${EXTENSION_DIR}" ] && [ -f "${EXTENSION_DIR}/manifest.json" ]; then
    CHROMIUM_FLAGS+=(--load-extension="${EXTENSION_DIR}")
    echo "[Chromium] Loading Chrome Bridge extension from ${EXTENSION_DIR}"
else
    echo "[Chromium] WARNING: Chrome Bridge extension not found at ${EXTENSION_DIR}"
fi

# Ensure profile directory exists
mkdir -p "${PROFILE_DIR}"

echo "[Chromium] Starting with persistent profile at ${PROFILE_DIR}"
exec chromium-browser "${CHROMIUM_FLAGS[@]}"

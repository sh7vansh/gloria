#!/bin/bash
# ============================================================================
# Gloria Doctor - Diagnostic tool for Gloria environment
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

status_ok() {
    echo -e "  ${GREEN}\u2713${NC} $1 ${DIM}$2${NC}"
}

status_fail() {
    echo -e "  ${RED}\u2717${NC} $1 ${DIM}$2${NC}"
}

status_warn() {
    echo -e "  ${YELLOW}\u26a0${NC} $1 ${DIM}$2${NC}"
}

failed=0

echo ""
echo -e "${BOLD}${CYAN}Gloria${NC}"
echo -e "${DIM}\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500${NC}"
echo ""

# Check if running inside container or on host
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    INSIDE_CONTAINER=true
else
    INSIDE_CONTAINER=false
fi

if [ "$INSIDE_CONTAINER" = true ]; then
    # ── Inside container checks ──
    
    # Desktop (Xvfb)
    if xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1; then
        status_ok "Desktop" "Xvfb running on ${DISPLAY:-:1}"
    else
        status_fail "Desktop" "Xvfb not detected"
        failed=1
    fi

    # VNC
    if ss -tlnp 2>/dev/null | grep -q ":${GLORIA_VNC_PORT:-5901}"; then
        status_ok "VNC" "listening on port ${GLORIA_VNC_PORT:-5901}"
    else
        status_fail "VNC" "not listening on port ${GLORIA_VNC_PORT:-5901}"
        failed=1
    fi

    # Chromium
    if pgrep -f chromium-browser >/dev/null 2>&1; then
        CHROME_PID=$(pgrep -f 'chromium-browser' | head -1)
        status_ok "Chromium" "running (PID: ${CHROME_PID})"
    else
        status_fail "Chromium" "not running"
        failed=1
    fi

    # Chromium profile
    PROFILE_DIR="${GLORIA_DATA:-/data}/chromium/profile"
    if [ -d "${PROFILE_DIR}" ]; then
        status_ok "Profile" "${PROFILE_DIR}"
    else
        status_fail "Profile" "directory missing at ${PROFILE_DIR}"
        failed=1
    fi

    # Extension
    EXT_DIR="/home/gloria/.chrome-bridge/extension"
    if [ -d "${EXT_DIR}" ] && [ -f "${EXT_DIR}/manifest.json" ]; then
        status_ok "Extension" "${EXT_DIR}"
    else
        status_fail "Extension" "not found at ${EXT_DIR}"
        failed=1
    fi

    # Native Messaging Host
    NMH="/home/gloria/.config/chromium/NativeMessagingHosts/com.chrome_bridge.native.json"
    if [ -f "${NMH}" ]; then
        LAUNCHER=$(python3 -c "import json; print(json.load(open('${NMH}'))['path'])" 2>/dev/null || echo "")
        if [ -n "${LAUNCHER}" ] && [ -x "${LAUNCHER}" ]; then
            status_ok "Native Host" "manifest OK, launcher executable"
        elif [ -n "${LAUNCHER}" ]; then
            status_warn "Native Host" "manifest OK, but launcher not executable: ${LAUNCHER}"
        else
            status_warn "Native Host" "manifest exists but could not read path"
        fi
    else
        status_fail "Native Host" "manifest not found at ${NMH}"
        failed=1
    fi

    # Chrome Bridge socket
    if [ -S /tmp/antigravity_chrome_bridge.sock ]; then
        status_ok "Chrome Bridge" "IPC socket active"
    else
        status_warn "Chrome Bridge" "IPC socket not found (normal if no tab is open)"
    fi

    # MCP Proxy
    if ss -tlnp 2>/dev/null | grep -q ":${GLORIA_MCP_PORT:-8787}"; then
        status_ok "MCP Proxy" "listening on port ${GLORIA_MCP_PORT:-8787}"
    else
        status_fail "MCP Proxy" "not listening on port ${GLORIA_MCP_PORT:-8787}"
        failed=1
    fi

else
    # ── Host-side checks ──

    # Docker
    if command -v docker >/dev/null 2>&1; then
        status_ok "Docker" "$(docker --version 2>/dev/null | head -c 40)"
    else
        status_fail "Docker" "not found"
        failed=1
    fi

    # Docker Compose
    if docker compose version >/dev/null 2>&1; then
        status_ok "Compose" "$(docker compose version 2>/dev/null | head -c 40)"
    else
        status_fail "Compose" "not found"
        failed=1
    fi

    # Container status
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q gloria-browser; then
        status_ok "Browser" "container running"
    else
        status_fail "Browser" "container not running"
        failed=1
    fi

    # Port checks
    WEB_PORT="${GLORIA_WEB_PORT:-8080}"
    MCP_PORT="${GLORIA_MCP_PORT:-8787}"

    if curl -sf "http://localhost:${WEB_PORT}/" >/dev/null 2>&1 || \
       ss -tlnp 2>/dev/null | grep -q ":${WEB_PORT}" || \
       netstat -tlnp 2>/dev/null | grep -q ":${WEB_PORT}"; then
        status_ok "Web Desktop" "http://localhost:${WEB_PORT}/"
    else
        status_warn "Web Desktop" "not responding on port ${WEB_PORT} (may still be starting)"
    fi

    if curl -sf "http://localhost:${MCP_PORT}/" >/dev/null 2>&1 || \
       ss -tlnp 2>/dev/null | grep -q ":${MCP_PORT}" || \
       netstat -tlnp 2>/dev/null | grep -q ":${MCP_PORT}"; then
        status_ok "MCP Proxy" "port ${MCP_PORT} reachable"
    else
        status_warn "MCP Proxy" "port ${MCP_PORT} not responding (may still be starting)"
    fi

    # Volume
    if docker volume inspect gloria-data >/dev/null 2>&1; then
        status_ok "Volume" "gloria-data exists"
    else
        status_fail "Volume" "gloria-data not found"
        failed=1
    fi
fi

echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All checks passed.${NC}"
else
    echo -e "${RED}${BOLD}Some checks failed.${NC} See above for details."
fi

echo ""
exit $failed

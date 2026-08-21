#!/bin/bash
# Gloria health check script for Docker

failed=0

# Check Xvfb
if xdpyinfo -display "${DISPLAY:-:1}" >/dev/null 2>&1; then
    : # OK
else
    echo "FAIL: Xvfb not running"
    failed=1
fi

# Check VNC
if ss -tlnp | grep -q ":${GLORIA_VNC_PORT:-5901}"; then
    : # OK
else
    echo "FAIL: VNC not listening"
    failed=1
fi

# Check Chromium process
if pgrep -x chromium >/dev/null 2>&1 || \
   pgrep -x chromium-browser >/dev/null 2>&1 || \
   pgrep -f 'chromium' >/dev/null 2>&1 || \
   pgrep -x google-chrome >/dev/null 2>&1 || \
   pgrep -f '/usr/bin/google-chrome' >/dev/null 2>&1; then
    :
else
    echo "FAIL: Chromium not running"
    failed=1
fi

# Check MCP Proxy port
if ss -tlnp | grep -q ":${GLORIA_MCP_PORT:-8787}"; then
    : # OK
else
    echo "FAIL: MCP Proxy not listening"
    failed=1
fi

# Check noVNC Web Desktop port
if ss -tlnp | grep -q ":${GLORIA_WEB_PORT:-8080}"; then
    : # OK
else
    echo "FAIL: noVNC Web Desktop not listening"
    failed=1
fi

exit $failed

#!/bin/bash
# ============================================================================
# Gloria Test Suite
# Automated tests for Gloria configuration and startup behavior
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

passed=0
failed=0
skipped=0

test_pass() {
    echo -e "  ${GREEN}PASS${NC} $1"
    ((passed++))
}

test_fail() {
    echo -e "  ${RED}FAIL${NC} $1 ${YELLOW}$2${NC}"
    ((failed++))
}

test_skip() {
    echo -e "  ${YELLOW}SKIP${NC} $1 ${YELLOW}$2${NC}"
    ((skipped++))
}

echo ""
echo -e "${BOLD}Gloria Test Suite${NC}"
echo "==========================================="
echo ""

# ── Compose Configuration ───────────────────────────────────────
echo -e "${BOLD}Compose Configuration${NC}"

if docker compose config >/dev/null 2>&1; then
    test_pass "compose.yaml is valid"
else
    test_fail "compose.yaml is invalid"
fi

# Check required services
for svc in gloria-browser gloria-guacd gloria-guacamole; do
    if docker compose config --services 2>/dev/null | grep -q "$svc"; then
        test_pass "Service '$svc' defined"
    else
        test_fail "Service '$svc' missing"
    fi
done

# Check volume
if docker compose config --volumes 2>/dev/null | grep -q "gloria-data"; then
    test_pass "Volume 'gloria-data' defined"
else
    test_fail "Volume 'gloria-data' missing"
fi

echo ""

# ── Docker Image ────────────────────────────────────────────────
echo -e "${BOLD}Docker Image${NC}"

if [ -f browser/Dockerfile ]; then
    test_pass "browser/Dockerfile exists"
else
    test_fail "browser/Dockerfile missing"
fi

if grep -q 'chromium-browser' browser/Dockerfile 2>/dev/null; then
    test_pass "Chromium installation in Dockerfile"
else
    test_fail "Chromium installation missing from Dockerfile"
fi

if grep -q 'antigravity-chrome-bridge' browser/Dockerfile 2>/dev/null; then
    test_pass "Chrome Bridge installation in Dockerfile"
else
    test_fail "Chrome Bridge installation missing from Dockerfile"
fi

if grep -q 'xfce4' browser/Dockerfile 2>/dev/null; then
    test_pass "XFCE installation in Dockerfile"
else
    test_fail "XFCE installation missing from Dockerfile"
fi

if grep -q 'tigervnc' browser/Dockerfile 2>/dev/null; then
    test_pass "VNC installation in Dockerfile"
else
    test_fail "VNC installation missing from Dockerfile"
fi

if grep -q 'uv' browser/Dockerfile 2>/dev/null; then
    test_pass "uv installation in Dockerfile"
else
    test_fail "uv installation missing from Dockerfile"
fi

echo ""

# ── Required Files ──────────────────────────────────────────────
echo -e "${BOLD}Required Files${NC}"

required_files=(
    "compose.yaml"
    "browser/Dockerfile"
    "browser/entrypoint.sh"
    "browser/supervisord.conf"
    "browser/scripts/start-vnc.sh"
    "browser/scripts/start-chromium.sh"
    "browser/scripts/start-mcp-proxy.sh"
    "browser/scripts/healthcheck.sh"
    "guacamole/config/guacamole.properties"
    "guacamole/config/user-mapping.xml"
    "scripts/doctor.sh"
    ".env.example"
    "README.md"
    "LICENSE"
)

for f in "${required_files[@]}"; do
    if [ -f "$f" ]; then
        test_pass "$f exists"
    else
        test_fail "$f missing"
    fi
done

echo ""

# ── Entrypoint Script ───────────────────────────────────────────
echo -e "${BOLD}Entrypoint Configuration${NC}"

if [ -x browser/entrypoint.sh ] || head -1 browser/entrypoint.sh 2>/dev/null | grep -q '#!/bin/bash'; then
    test_pass "entrypoint.sh has bash shebang"
else
    test_fail "entrypoint.sh missing bash shebang"
fi

# Check for critical setup steps
if grep -q 'chromium/profile' browser/entrypoint.sh 2>/dev/null; then
    test_pass "entrypoint creates persistent profile directory"
else
    test_fail "entrypoint missing persistent profile setup"
fi

if grep -q 'chrome-bridge.*setup\|antigravity-chrome-bridge.*setup' browser/entrypoint.sh 2>/dev/null; then
    test_pass "entrypoint runs Chrome Bridge setup"
else
    test_fail "entrypoint missing Chrome Bridge setup"
fi

if grep -q 'policies/managed' browser/entrypoint.sh 2>/dev/null; then
    test_pass "entrypoint configures extension policy"
else
    test_fail "entrypoint missing extension policy configuration"
fi

if grep -q 'NativeMessagingHosts' browser/entrypoint.sh 2>/dev/null; then
    test_pass "entrypoint configures Native Messaging"
else
    test_fail "entrypoint missing Native Messaging configuration"
fi

if grep -q 'supervisord' browser/entrypoint.sh 2>/dev/null; then
    test_pass "entrypoint starts supervisord"
else
    test_fail "entrypoint missing supervisord startup"
fi

echo ""

# ── Chromium Launch Script ──────────────────────────────────────
echo -e "${BOLD}Chromium Configuration${NC}"

if grep -q 'user-data-dir' browser/scripts/start-chromium.sh 2>/dev/null; then
    test_pass "Chromium uses custom user-data-dir"
else
    test_fail "Chromium missing user-data-dir flag"
fi

if grep -q 'load-extension' browser/scripts/start-chromium.sh 2>/dev/null; then
    test_pass "Chromium loads Chrome Bridge extension"
else
    test_fail "Chromium missing extension loading"
fi

if grep -q 'no-first-run' browser/scripts/start-chromium.sh 2>/dev/null; then
    test_pass "Chromium skips first-run experience"
else
    test_fail "Chromium missing no-first-run flag"
fi

echo ""

# ── Guacamole Configuration ─────────────────────────────────────
echo -e "${BOLD}Guacamole Configuration${NC}"

if grep -q 'gloria-guacd' guacamole/config/guacamole.properties 2>/dev/null; then
    test_pass "Guacamole connects to guacd"
else
    test_fail "Guacamole missing guacd connection"
fi

if grep -q 'vnc' guacamole/config/user-mapping.xml 2>/dev/null; then
    test_pass "Guacamole uses VNC protocol"
else
    test_fail "Guacamole missing VNC protocol"
fi

if grep -q 'gloria-browser' guacamole/config/user-mapping.xml 2>/dev/null; then
    test_pass "Guacamole targets gloria-browser hostname"
else
    test_fail "Guacamole missing gloria-browser target"
fi

echo ""

# ── Runtime Tests (if containers are running) ───────────────────
echo -e "${BOLD}Runtime Tests${NC}"

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q gloria-browser; then
    test_pass "gloria-browser container running"

    # Test persistent volume mount
    if docker exec gloria-browser test -d /data/chromium/profile 2>/dev/null; then
        test_pass "Persistent profile directory exists in container"
    else
        test_fail "Persistent profile directory missing"
    fi

    # Test extension exists
    if docker exec gloria-browser test -f /home/gloria/.chrome-bridge/extension/manifest.json 2>/dev/null; then
        test_pass "Chrome Bridge extension installed in container"
    else
        test_fail "Chrome Bridge extension missing in container"
    fi

    # Test Native Messaging manifest
    if docker exec gloria-browser test -f /home/gloria/.config/chromium/NativeMessagingHosts/com.chrome_bridge.native.json 2>/dev/null; then
        test_pass "Native Messaging manifest exists"
    else
        test_fail "Native Messaging manifest missing"
    fi

    # Test Native Messaging launcher executable
    if docker exec gloria-browser test -x /home/gloria/.chrome-bridge/native-host.sh 2>/dev/null; then
        test_pass "Native Messaging launcher is executable"
    else
        test_warn "Native Messaging launcher not executable or missing"
    fi

    # Test extension policy exists
    if docker exec gloria-browser test -f /etc/chromium-browser/policies/managed/gloria-extensions.json 2>/dev/null; then
        test_pass "Chromium extension policy exists"
    else
        test_fail "Chromium extension policy missing"
    fi

    # Test Xvfb
    if docker exec gloria-browser bash -c 'xdpyinfo -display :1 >/dev/null 2>&1'; then
        test_pass "Xvfb running inside container"
    else
        test_fail "Xvfb not running"
    fi

    # Test VNC port
    if docker exec gloria-browser bash -c 'ss -tlnp | grep -q :5901'; then
        test_pass "VNC listening on port 5901"
    else
        test_fail "VNC not listening"
    fi

    # Test Chromium process
    if docker exec gloria-browser pgrep -f chromium-browser >/dev/null 2>&1; then
        test_pass "Chromium process running"
    else
        test_fail "Chromium not running"
    fi

    # Test MCP Proxy port
    if docker exec gloria-browser bash -c 'ss -tlnp | grep -q :8787'; then
        test_pass "MCP Proxy listening on port 8787"
    else
        test_fail "MCP Proxy not listening"
    fi

    # Test Chromium uses persistent profile
    if docker exec gloria-browser bash -c 'pgrep -a chromium-browser | grep -q user-data-dir'; then
        test_pass "Chromium using persistent profile"
    else
        test_fail "Chromium not using persistent profile"
    fi

else
    test_skip "Runtime tests" "(containers not running)"
fi

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q gloria-guacd; then
    test_pass "gloria-guacd container running"
else
    test_skip "gloria-guacd" "(not running)"
fi

if docker ps --format '{{.Names}}' 2>/dev/null | grep -q gloria-guacamole; then
    test_pass "gloria-guacamole container running"
else
    test_skip "gloria-guacamole" "(not running)"
fi

# MCP port reachability from host
MCP_PORT="${GLORIA_MCP_PORT:-8787}"
if curl -sf "http://localhost:${MCP_PORT}/" >/dev/null 2>&1; then
    test_pass "MCP endpoint reachable from host"
else
    test_skip "MCP endpoint" "(not reachable from host)"
fi

# Guacamole reachability from host
GUAC_PORT="${GLORIA_GUAC_PORT:-8080}"
if curl -sf "http://localhost:${GUAC_PORT}/guacamole/" >/dev/null 2>&1; then
    test_pass "Guacamole reachable from host"
else
    test_skip "Guacamole" "(not reachable from host)"
fi

echo ""

# ── Persistence Test ────────────────────────────────────────────
echo -e "${BOLD}Persistence Test${NC}"

if docker volume inspect gloria-data >/dev/null 2>&1; then
    test_pass "gloria-data volume exists"
else
    test_skip "Persistence" "(volume not created yet)"
fi

echo ""

# ── Summary ─────────────────────────────────────────────────────
echo "==========================================="
total=$((passed + failed + skipped))
echo -e "  ${GREEN}${passed} passed${NC}  ${RED}${failed} failed${NC}  ${YELLOW}${skipped} skipped${NC}  (${total} total)"
echo "==========================================="
echo ""

if [ $failed -gt 0 ]; then
    exit 1
fi
exit 0

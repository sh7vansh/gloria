#!/bin/bash
set -e

# ============================================================================
# Gloria Browser Container Entrypoint
# Initializes persistent storage, configures Chrome Bridge, and starts services
# ============================================================================

echo "═══════════════════════════════════════════════════════"
echo "  Gloria — Persistent Remote Chromium Workstation"
echo "═══════════════════════════════════════════════════════"
echo ""

DATA_DIR="${GLORIA_DATA:-/data}"
HOME_DIR="/home/gloria"

# ── Phase 1: Prepare persistent storage ──────────────────────────────────────
echo "[1/8] Preparing persistent storage..."
mkdir -p "${DATA_DIR}/chromium/profile"
mkdir -p "${DATA_DIR}/downloads"
mkdir -p "${DATA_DIR}/desktop"
mkdir -p "${DATA_DIR}/gloria/config"
mkdir -p "${DATA_DIR}/gloria/logs"
mkdir -p "${DATA_DIR}/gloria/state"
chown -R gloria:gloria "${DATA_DIR}"
echo "  ✓ Persistent directories ready at ${DATA_DIR}"

# ── Phase 2: Link persistent directories to home ────────────────────────────
echo "[2/8] Linking persistent directories..."
# Downloads
ln -sfn "${DATA_DIR}/downloads" "${HOME_DIR}/Downloads"
# Desktop
ln -sfn "${DATA_DIR}/desktop" "${HOME_DIR}/Desktop"
chown -h gloria:gloria "${HOME_DIR}/Downloads" "${HOME_DIR}/Desktop"
echo "  ✓ Home directories linked to persistent storage"

# ── Phase 3: Configure DBus ─────────────────────────────────────────────────
echo "[3/8] Configuring DBus..."
mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
    rm -f /run/dbus/pid
fi
dbus-uuidgen --ensure=/etc/machine-id 2>/dev/null || true
echo "  ✓ DBus configured"

# ── Phase 4: Configure VNC password ─────────────────────────────────────────
echo "[4/8] Configuring VNC..."
mkdir -p "${HOME_DIR}/.vnc"
echo "${GLORIA_VNC_PASSWORD:-gloria}" | vncpasswd -f > "${HOME_DIR}/.vnc/passwd"
chmod 600 "${HOME_DIR}/.vnc/passwd"
chown -R gloria:gloria "${HOME_DIR}/.vnc"
echo "  ✓ VNC password configured"

# ── Phase 5: Run Chrome Bridge setup ────────────────────────────────────────
echo "[5/8] Configuring Chrome Bridge..."
su - gloria -c '
    export PATH="/home/gloria/.local/bin:${PATH}"
    export HOME="/home/gloria"
    
    # Run Chrome Bridge setup non-interactively
    antigravity-chrome-bridge setup --no-listen --quiet 2>/dev/null || true
    echo "  ✓ Chrome Bridge setup complete"
'

# ── Phase 6: Configure Chromium enterprise extension policy ─────────────────
echo "[6/8] Configuring Chromium extension policy..."

# Determine the extension path from Chrome Bridge's install
CB_EXTENSION_DIR="${HOME_DIR}/.chrome-bridge/extension"

# Fallback: find extension via uv tool directory
if [ ! -d "${CB_EXTENSION_DIR}" ]; then
    # Look in the uv tool installation
    UV_TOOL_EXT=$(find /home/gloria/.local/share/uv/tools -name 'extension' -type d 2>/dev/null | head -1)
    if [ -n "${UV_TOOL_EXT}" ] && [ -d "${UV_TOOL_EXT}" ]; then
        mkdir -p "${HOME_DIR}/.chrome-bridge"
        cp -r "${UV_TOOL_EXT}" "${CB_EXTENSION_DIR}"
        chown -R gloria:gloria "${HOME_DIR}/.chrome-bridge"
    fi
fi

# Verify extension exists
if [ -d "${CB_EXTENSION_DIR}" ] && [ -f "${CB_EXTENSION_DIR}/manifest.json" ]; then
    echo "  ✓ Chrome Bridge extension found at ${CB_EXTENSION_DIR}"
else
    echo "  ⚠ Chrome Bridge extension not found, attempting recovery..."
    # Clone from repository as last resort
    su - gloria -c '
        cd /tmp
        git clone --depth 1 https://github.com/sh7vansh/chrome-bridge.git cb-temp 2>/dev/null || true
        if [ -d /tmp/cb-temp/extension ]; then
            mkdir -p /home/gloria/.chrome-bridge
            cp -r /tmp/cb-temp/extension /home/gloria/.chrome-bridge/extension
            echo "  ✓ Extension recovered from repository"
        fi
        rm -rf /tmp/cb-temp
    '
    CB_EXTENSION_DIR="${HOME_DIR}/.chrome-bridge/extension"
fi

# Set up Chromium managed policies for automatic extension loading
# This uses the ExtensionInstallForcelist policy with a local CRX-less path
mkdir -p /etc/chromium-browser/policies/managed
mkdir -p /etc/chromium/policies/managed

# Read the extension ID from the manifest's key field
# The Chrome Bridge extension has a hardcoded key that produces this ID:
UBLOCK_EXT_ID="ddkjiahejlhfcafbddmgiahcphecmpfh"

# Ensure extension directories are owned by gloria
if [ -d /opt/extensions ]; then
    chown -R gloria:gloria /opt/extensions
fi

# Approach 1: Chromium policies (for managed installs)
cat > /etc/chromium-browser/policies/managed/gloria-extensions.json << POLICY
{
    "ExtensionInstallAllowlist": ["${EXT_ID}", "${UBLOCK_EXT_ID}"],
    "ExtensionSettings": {
        "${EXT_ID}": {
            "installation_mode": "allowed"
        },
        "${UBLOCK_EXT_ID}": {
            "installation_mode": "allowed"
        }
    },
    "NativeMessagingAllowlist": ["com.chrome_bridge.native"],
    "BookmarkBarEnabled": true
}
POLICY

# uBlock Origin Lite Managed Storage Policy (enforce Basic mode)
cat > /etc/chromium-browser/policies/managed/${UBLOCK_EXT_ID}.json << POLICY
{
    "defaultFiltering": "basic",
    "disableFirstRunPage": true
}
POLICY
cp /etc/chromium-browser/policies/managed/${UBLOCK_EXT_ID}.json /etc/chromium/policies/managed/ 2>/dev/null || true
cp /etc/chromium-browser/policies/managed/${UBLOCK_EXT_ID}.json /etc/opt/chrome/policies/managed/ 2>/dev/null || true

echo "  ✓ Chromium extension policy configured (Chrome Bridge + uBlock Origin Lite [Basic Mode])"

# ── Phase 7: Configure Native Messaging for Chromium ───────────────────────
echo "[7/8] Verifying Native Messaging configuration..."

# Ensure Native Messaging manifest exists for Chromium
NMH_DIR="${HOME_DIR}/.config/chromium/NativeMessagingHosts"
mkdir -p "${NMH_DIR}"

# The Chrome Bridge setup should have already created this, but verify
NMH_MANIFEST="${NMH_DIR}/com.chrome_bridge.native.json"
if [ -f "${NMH_MANIFEST}" ]; then
    echo "  ✓ Native Messaging manifest exists at ${NMH_MANIFEST}"
else
    echo "  ⚠ Native Messaging manifest missing, creating..."
    LAUNCHER="${HOME_DIR}/.chrome-bridge/native-host.sh"
    if [ ! -f "${LAUNCHER}" ]; then
        # Find the native host script
        NH_PY=$(find /home/gloria/.local/share/uv/tools -name 'native_host.py' 2>/dev/null | head -1)
        if [ -z "${NH_PY}" ]; then
            NH_PY="${HOME_DIR}/.chrome-bridge/native_host.py"
        fi
        PYTHON_BIN=$(which python3)
        mkdir -p "${HOME_DIR}/.chrome-bridge"
        cat > "${LAUNCHER}" << LAUNCHER_SCRIPT
#!/bin/sh
export PYTHONIOENCODING=utf-8
export PYTHONUTF8=1
exec ${PYTHON_BIN} ${NH_PY} "\$@"
LAUNCHER_SCRIPT
        chmod +x "${LAUNCHER}"
    fi
    
    cat > "${NMH_MANIFEST}" << MANIFEST
{
    "name": "com.chrome_bridge.native",
    "description": "Chrome Bridge Native Messaging Host for AI Procedural Automation",
    "path": "${LAUNCHER}",
    "type": "stdio",
    "allowed_origins": [
        "chrome-extension://${EXT_ID}/"
    ]
}
MANIFEST
    chown -R gloria:gloria "${NMH_DIR}"
    echo "  ✓ Native Messaging manifest created"
fi

# Also ensure manifest for custom user-data-dir and google-chrome-for-testing
mkdir -p "${DATA_DIR}/chromium/profile/NativeMessagingHosts"
cp "${NMH_MANIFEST}" "${DATA_DIR}/chromium/profile/NativeMessagingHosts/com.chrome_bridge.native.json" 2>/dev/null || true
chown -R gloria:gloria "${DATA_DIR}/chromium/profile/NativeMessagingHosts" 2>/dev/null || true

mkdir -p "${HOME_DIR}/.config/google-chrome-for-testing/NativeMessagingHosts"
cp "${NMH_MANIFEST}" "${HOME_DIR}/.config/google-chrome-for-testing/NativeMessagingHosts/com.chrome_bridge.native.json" 2>/dev/null || true
chown -R gloria:gloria "${HOME_DIR}/.config/google-chrome-for-testing" 2>/dev/null || true

mkdir -p "${HOME_DIR}/.config/google-chrome/NativeMessagingHosts"
cp "${NMH_MANIFEST}" "${HOME_DIR}/.config/google-chrome/NativeMessagingHosts/com.chrome_bridge.native.json" 2>/dev/null || true
chown -R gloria:gloria "${HOME_DIR}/.config/google-chrome" 2>/dev/null || true

mkdir -p /etc/chromium/native-messaging-hosts /etc/opt/chrome/native-messaging-hosts
cp "${NMH_MANIFEST}" /etc/chromium/native-messaging-hosts/com.chrome_bridge.native.json 2>/dev/null || true
cp "${NMH_MANIFEST}" /etc/opt/chrome/native-messaging-hosts/com.chrome_bridge.native.json 2>/dev/null || true
chmod 644 /etc/chromium/native-messaging-hosts/*.json /etc/opt/chrome/native-messaging-hosts/*.json 2>/dev/null || true

echo "  ✓ Native Messaging verified across all profile & browser directories"

# ── Phase 8: Start supervisor ───────────────────────────────────────────────
echo "[8/8] Starting services..."
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Gloria is starting up!"
echo ""
echo "  🖥  Guacamole:  http://localhost:${GLORIA_GUAC_PORT:-8080}/guacamole/"
echo "  🤖  MCP:        http://localhost:${GLORIA_MCP_PORT:-8787}/mcp"
echo "═══════════════════════════════════════════════════════"
echo ""

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/gloria.conf

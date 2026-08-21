# ============================================================================
# Gloria Browser Container
# Ubuntu + XFCE + VNC + Chromium + Chrome Bridge + MCP Proxy
# ============================================================================
FROM ubuntu:24.04

LABEL maintainer="Gloria Contributors"
LABEL description="Persistent Chromium workstation with Chrome Bridge and MCP"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ── System packages ─────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    sudo \
    bash \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    locales \
    dbus \
    dbus-x11 \
    # Lightweight Window Manager & Taskbar
    openbox \
    tint2 \
    # X11
    xvfb \
    x11-utils \
    x11-xserver-utils \
    xdg-utils \
    # VNC & HTML5 noVNC (Zero-password web desktop)
    tigervnc-common \
    tigervnc-tools \
    tigervnc-scraping-server \
    novnc \
    websockify \
    # Fonts
    fonts-liberation \
    fonts-dejavu-core \
    fonts-noto-color-emoji \
    fontconfig \
    # Networking & certificates
    net-tools \
    iproute2 \
    openssl \
    # Process management
    supervisor \
    procps \
    # Build essentials for Python
    python3 \
    python3-pip \
    python3-venv \
    git \
    # Misc
    xdotool \
    xclip \
    && locale-gen en_US.UTF-8 \
    && echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale&quality=8&compression=2"></head><body></body></html>' > /usr/share/novnc/index.html \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify VNC tools exist
RUN command -v vncpasswd && \
    command -v x0tigervncserver
    
# ── Install Chromium (Chrome for Testing build with --load-extension support) ──
RUN apt-get update && apt-get install -y --no-install-recommends \
        unzip \
        libnss3 \
        libasound2t64 \
        libgbm1 \
        libxss1 \
        libatk1.0-0t64 \
        libatk-bridge2.0-0t64 \
        libatspi2.0-0t64 \
        libgtk-3-0t64 \
        libcups2t64 \
        libdrm2 \
    && rm -rf /var/lib/apt/lists/* \
    && wget -q -O /tmp/chrome.zip https://storage.googleapis.com/chrome-for-testing-public/152.0.7977.54/linux64/chrome-linux64.zip \
    && unzip -q /tmp/chrome.zip -d /opt/ \
    && rm -f /tmp/chrome.zip \
    && ln -s /opt/chrome-linux64/chrome /usr/bin/chromium \
    && ln -s /opt/chrome-linux64/chrome /usr/bin/chromium-browser \
    && chmod +x /opt/chrome-linux64/chrome

# ── Install uBlock Origin Lite (Preinstalled MV3 Ad-Blocker) ────────────────
RUN mkdir -p /opt/extensions/ublock-origin-lite \
    && wget -q -O /tmp/ubolite.zip https://github.com/uBlockOrigin/uBOL-home/releases/download/2026.820.1159/uBOLite_2026.820.1159.chromium.zip \
    && unzip -q /tmp/ubolite.zip -d /opt/extensions/ublock-origin-lite/ \
    && rm -f /tmp/ubolite.zip \
    && python3 -c "import json; p='/opt/extensions/ublock-origin-lite/manifest.json'; d=json.load(open(p)); d['key']='MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqJE6DLdtfHXfeaGDSKdUuCvvb3pYEpH7jsuYMdExgIqmKRux2dknlJAnYkamBMcirGBfwCFjqE++TAkCs8AcrYLOGRRMt8oa7DXuFWzgtQpkwigI1+dnIuYLzERLQx/O02/p//fHdDQfxWKvySnN+VHdINOHsUD6OcoC5I7CXIBSrateRpRGpFxxR6F4nWvK3aq2j3L6A/qRg+pr0QVqL8p1TOJG+vSh234YHnsO9Dsys+VNbT0k0n8enCm/VsOCMjihgHpmftd1bSfSr8s1IwBuFdaLVQKghyDn1PvhFNBkuAXu+J/z0/o5Nio+/bIz406ECI9Qtkr9kqVboFDtzwIDAQAB'; json.dump(d, open(p, 'w'), indent=2)" \
    && python3 -c "p='/opt/extensions/ublock-origin-lite/js/mode-manager.js'; s=open(p).read().replace(\"optimal: [ 'all-urls' ]\", \"optimal: [],\n    basic: [ 'all-urls' ]\"); open(p, 'w').write(s)" \
    && chmod -R 755 /opt/extensions/ublock-origin-lite

# ── Create gloria user ──────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash -G sudo gloria \
    && echo "gloria ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/gloria \
    && chown -R gloria:gloria /opt/extensions

# ── Install uv ──────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && cp /root/.local/bin/uv /usr/local/bin/uv \
    && cp /root/.local/bin/uvx /usr/local/bin/uvx \
    && chmod +x /usr/local/bin/uv /usr/local/bin/uvx

# ── Install Chrome Bridge ──────────────────────────────────────────────────
USER gloria
ENV HOME=/home/gloria
ENV PATH="/home/gloria/.local/bin:${PATH}"

# Install chrome-bridge as a uv tool
RUN uv tool install antigravity-chrome-bridge

# Install mcp-proxy for remote MCP access
RUN uv tool install "mcp-proxy" --with "mcp<2.0.0"

USER root

# ── Copy Gloria scripts and configuration ───────────────────────────────────
COPY --chown=gloria:gloria scripts/ /opt/gloria/scripts/
COPY --chown=gloria:gloria config/ /opt/gloria/config/
COPY --chown=gloria:gloria entrypoint.sh /opt/gloria/entrypoint.sh
COPY --chown=gloria:gloria supervisord.conf /etc/supervisor/conf.d/gloria.conf

RUN chmod +x /opt/gloria/entrypoint.sh \
    && chmod +x /opt/gloria/scripts/*.sh 2>/dev/null || true

# ── Environment defaults ───────────────────────────────────────────────────
ENV DISPLAY=:1
ENV GLORIA_DATA=/data
ENV GLORIA_SCREEN_WIDTH=1920
ENV GLORIA_SCREEN_HEIGHT=1080
ENV GLORIA_SCREEN_DEPTH=24
ENV GLORIA_VNC_PORT=5901
ENV GLORIA_MCP_PORT=8787
ENV GLORIA_VNC_PASSWORD=gloria

EXPOSE 8080 5901 8787

ENTRYPOINT ["/opt/gloria/entrypoint.sh"]

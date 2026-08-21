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
    # XFCE Desktop
    xfce4 \
    xfce4-terminal \
    xfce4-taskmanager \
    # X11
    xvfb \
    x11-utils \
    x11-xserver-utils \
    xdg-utils \
    # VNC
    tigervnc-standalone-server \
    tigervnc-common \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Install Chromium ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium-browser \
    chromium-codecs-ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Create gloria user ──────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash -G sudo gloria \
    && echo "gloria ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/gloria

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

EXPOSE 5901 8787

ENTRYPOINT ["/opt/gloria/entrypoint.sh"]

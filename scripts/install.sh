#!/bin/bash
# ============================================================================
# Gloria Install Script
# Quick setup for first-time users
# ============================================================================

set -e

echo ""
echo "Gloria — Persistent Remote Chromium Workstation"
echo "================================================"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is required but not installed."
    echo "Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker compose version &>/dev/null; then
    echo "ERROR: Docker Compose V2 is required."
    echo "Update Docker or install the compose plugin."
    exit 1
fi

echo "\u2713 Docker and Docker Compose detected"
echo ""

# Create .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "\u2713 Created .env from .env.example"
else
    echo "\u2713 .env already exists"
fi

# Build and start
echo ""
echo "Building Gloria (this may take a few minutes on first run)..."
echo ""

docker compose build
docker compose up -d

echo ""
echo "================================================"
echo "  Gloria is starting!"
echo ""
echo "  Desktop:  http://localhost:${GLORIA_GUAC_PORT:-8080}/guacamole/"
echo "            Login: gloria / gloria"
echo ""
echo "  MCP:      http://localhost:${GLORIA_MCP_PORT:-8787}/mcp"
echo "================================================"
echo ""
echo "Run './scripts/doctor.sh' to check status."
echo ""

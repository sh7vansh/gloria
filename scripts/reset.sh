#!/bin/bash
# Reset Gloria (WARNING: destroys all persistent data)
set -e

echo "WARNING: This will destroy all Gloria data including:"
echo "  - Browser profile (cookies, history, sessions)"
echo "  - Downloads"
echo "  - Configuration"
echo ""
read -p "Are you sure? (type 'yes' to confirm): " confirm

if [ "$confirm" = "yes" ]; then
    docker compose down -v
    echo "Gloria has been reset. Run 'docker compose up -d' to start fresh."
else
    echo "Reset cancelled."
fi

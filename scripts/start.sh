#!/bin/bash
# Start Gloria
set -e
docker compose up -d
echo "Gloria started. Run './scripts/doctor.sh' to check status."

#!/bin/bash
# Stop Gloria (preserves data)
set -e
docker compose down
echo "Gloria stopped. Data is preserved in the gloria-data volume."

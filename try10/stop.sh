#!/bin/bash
# Stop FreeSWITCH docker compose

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping FreeSWITCH..."
docker compose -f docker-compose.source.yml down

echo "FreeSWITCH stopped."

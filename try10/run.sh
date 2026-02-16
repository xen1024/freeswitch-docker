#!/bin/bash
# Start FreeSWITCH docker compose

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting FreeSWITCH..."
docker compose -f docker-compose.source.yml up --build

echo ""
echo "To view logs: docker compose -f docker-compose.source.yml logs -f"
echo "To access CLI: docker exec -it freeswitch-source fs_cli"

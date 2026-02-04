#!/bin/bash

# Stop FreeSWITCH Docker container (local build)
docker-compose -f docker-compose-2.yml down

echo "FreeSWITCH container stopped"

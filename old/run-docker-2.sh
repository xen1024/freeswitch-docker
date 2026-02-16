#!/bin/bash

# Start FreeSWITCH Docker container (local build)
docker-compose -f docker-compose-2.yml up --build

echo "FreeSWITCH container started"

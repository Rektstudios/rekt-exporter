#!/bin/bash
# Complete startup script for instance logging
set -e
source .env
echo "Starting instance logging setup..."
# Start fluent-bit
echo "Starting log shipping..."
docker compose up -d fluent-bit

# Optional: Create Grafana dashboard
if [ ! -z "$GRAFANA_URL" ] && [ ! -z "$GRAFANA_USER" ] && [ ! -z "$GRAFANA_PASS" ]; then
    echo "Creating Grafana dashboard..."
    ./create-grafana-dashboard.sh
fi
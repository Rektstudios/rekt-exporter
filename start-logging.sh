#!/bin/bash
# Complete startup script for instance logging
set -e

echo "Starting instance logging setup..."

# Fetch AWS metadata and add to .env
echo "Fetching AWS metadata..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# Add AWS metadata to .env
echo "AWS_INSTANCE_ID=$AWS_INSTANCE_ID" >> .env
echo "AWS_REGION=$AWS_REGION" >> .env
echo "LOG_TIMESTAMP=$(date +%Y%m%d_%H%M%S)" >> .env
echo "Environment configured with AWS metadata"

# Source updated .env
source .env

# Start fluent-bit
echo "Starting log shipping..."
docker compose up -d fluent-bit

# Optional: Create Grafana dashboard
if [ ! -z "$GRAFANA_URL" ] && [ ! -z "$GRAFANA_USER" ] && [ ! -z "$GRAFANA_PASS" ]; then
    echo "Creating Grafana dashboard..."
    chmod +x create-grafana-dashboard.sh
    ./create-grafana-dashboard.sh
fi
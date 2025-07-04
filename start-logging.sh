#!/bin/bash

# Complete startup script for temporary instance logging
set -e

echo "Starting temporary instance logging setup..."

# Fetch AWS metadata
echo "Fetching AWS metadata..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

# Update .env with dynamic values
echo "AWS_INSTANCE_ID=$INSTANCE_ID" >> .env
echo "AWS_REGION=$REGION" >> .env
echo "LOG_TIMESTAMP=$(date +%Y%m%d_%H%M%S)" >> .env

echo "Environment configured:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Region: $REGION"
echo "  Game Environment: $GAME_ENV"
echo "  Log Session: $(date +%Y%m%d_%H%M%S)"

# Start fluent-bit
echo "Starting log shipping..."
docker compose up -d fluent-bit

# Optional: Create Grafana dashboard
if [ ! -z "$GRAFANA_URL" ] && [ ! -z "$GRAFANA_USER" ] && [ ! -z "$GRAFANA_PASS" ]; then
    echo "Creating Grafana dashboard..."
    ./create-grafana-dashboard.sh
fi

echo "Logging setup complete!"
echo "Logs will be available in Grafana with labels:"
echo "  aws_instance_id=$INSTANCE_ID"
echo "  aws_region=$REGION"
echo "  game_env=$GAME_ENV"
echo ""
echo "Use this query in Grafana: {aws_instance_id=\"$INSTANCE_ID\"}"
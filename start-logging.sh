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

# Clean up any existing Fluent Bit state
echo "Cleaning up previous Fluent Bit state..."
docker compose down fluent-bit 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

# Start fluent-bit
echo "Starting log shipping..."
docker compose up -d fluent-bit

# Optional: Create Grafana dashboard
if [ ! -z "$GRAFANA_URL" ] && [ ! -z "$GRAFANA_USER" ] && [ ! -z "$GRAFANA_PASS" ]; then
    echo "Creating Grafana dashboard..."
    
    # Dashboard configuration
    DASHBOARD_NAME="Game Logs - ${GAME_ENV} - ${AWS_INSTANCE_ID} - $(date +%Y-%m-%d-%H-%M-%S)"
    DASHBOARD_UID="game-logs-${AWS_INSTANCE_ID}-$(date +%Y%m%d)"
    
    # Date components for folder structure
    CURRENT_YEAR=$(date +%Y)
    CURRENT_MONTH=$(date +%m)
    CURRENT_DAY=$(date +%d)
    
    # Function to create folder if it doesn't exist
    create_folder_if_not_exists() {
        local folder_title="$1"
        local parent_uid="$2"
        
        # Check if folder exists
        local folder_search=$(curl -s "https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/search?query=${folder_title}&type=dash-folder&folderIds=${parent_uid}" | jq -r '.[] | select(.title == "'${folder_title}'") | .uid')
        
        if [ -z "$folder_search" ] || [ "$folder_search" = "null" ]; then
            # Create folder
            local folder_json=$(cat << EOF
{
  "title": "${folder_title}",
  "parentUid": "${parent_uid}"
}
EOF
            )
            
            local result=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d "$folder_json" \
                "https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/folders")
            
            echo $(echo "$result" | jq -r '.uid')
        else
            echo "$folder_search"
        fi
    }
    
    # Create folder hierarchy: PARENT/YEAR/MONTH/DAY
    echo "Creating folder structure..."
    YEAR_FOLDER_UID=$(create_folder_if_not_exists "${CURRENT_YEAR}" "${GRAFANA_PARENT_FOLDER_UID}")
    MONTH_FOLDER_UID=$(create_folder_if_not_exists "${CURRENT_MONTH}" "${YEAR_FOLDER_UID}")
    DAY_FOLDER_UID=$(create_folder_if_not_exists "${CURRENT_DAY}" "${MONTH_FOLDER_UID}")
    
    echo "Folder structure created: ${GRAFANA_PARENT_FOLDER_UID}/${CURRENT_YEAR}/${CURRENT_MONTH}/${CURRENT_DAY}"
    echo "Final folder UID: ${DAY_FOLDER_UID}"
    
    # Create dashboard JSON
    cat > dashboard.json << EOF
{
  "dashboard": {
    "annotations": {
      "list": [
        {
          "builtIn": 1,
          "datasource": {
            "type": "grafana",
            "uid": "-- Grafana --"
          },
          "enable": true,
          "hide": true,
          "iconColor": "rgba(0, 211, 255, 1)",
          "name": "Annotations & Alerts",
          "type": "dashboard"
        }
      ]
    },
    "editable": true,
    "fiscalYearStartMonth": 0,
    "graphTooltip": 0,
    "id": null,
    "links": [],
    "panels": [
      {
        "datasource": {
          "type": "loki",
          "uid": "${LOKI_DATASOURCE_UID}"
        },
        "fieldConfig": {
          "defaults": {},
          "overrides": []
        },
        "gridPos": {
          "h": 14,
          "w": 24,
          "x": 0,
          "y": 0
        },
        "id": 1,
        "options": {
          "dedupStrategy": "none",
          "enableInfiniteScrolling": false,
          "enableLogDetails": true,
          "prettifyLogMessage": false,
          "showCommonLabels": false,
          "showLabels": true,
          "showTime": true,
          "sortOrder": "Descending",
          "wrapLogMessage": false
        },
        "pluginVersion": "11.5.2",
        "targets": [
          {
            "datasource": {
              "type": "loki",
              "uid": "${LOKI_DATASOURCE_UID}"
            },
            "direction": "backward",
            "editorMode": "builder",
            "expr": "{instance=\"${APP_NAME}-${GAME_ENV}\"}",
            "queryType": "range",
            "refId": "A"
          }
        ],
        "title": "Game Logs - ${AWS_INSTANCE_ID}",
        "type": "logs"
      }
    ],
    "preload": false,
    "refresh": "",
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-7d",
      "to": "now"
    },
    "timepicker": {},
    "timezone": "browser",
    "title": "${DASHBOARD_NAME}",
    "uid": "${DASHBOARD_UID}",
    "tags": ["Cryptorun", "Streaming-logs", "${GAME_ENV}", "${AWS_REGION}"]
  },
  "folderUid": "${DAY_FOLDER_UID}",
  "overwrite": true
}
EOF
    
    # Create the dashboard via Grafana API
    curl -X POST \
      -H "Content-Type: application/json" \
      -d @dashboard.json \
      https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/dashboards/db
    
    echo "Dashboard created for instance ${AWS_INSTANCE_ID}"
    echo "Dashboard UID: ${DASHBOARD_UID}"
    
    # Clean up temporary file
    rm -f dashboard.json
fi
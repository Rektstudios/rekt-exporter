#!/bin/bash
source .env
# Create Grafana dashboard for this instance
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
DASHBOARD_NAME="Game Logs - ${GAME_ENV} - ${AWS_INSTANCE_ID} - $(date +%Y-%m-%d-%H-%M-%S)"
DASHBOARD_UID="game-logs-${AWS_INSTANCE_ID}-$(date +%Y%m%d)"
#GRAFANA_FOLDER_UID=$(curl -s "https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/search?query='$GRAFANA_FOLDER_NAME'&type=dash-folder" | jq -r '.[] | select(.title == '$GRAFANA_FOLDER_NAME') | .uid')
#LOKI_DATASOURCE_UID=$(curl -s "https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/datasources" | jq -r '.[] | select(.name == '$LOKI_DATASOURCE_NAME') | .uid')

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
  "folderUid": "${GRAFANA_FOLDER_UID}",
  "overwrite": true
}
EOF

# Create the dashboard via Grafana API (if credentials are available)
curl -X POST \
  -H "Content-Type: application/json" \
  -d @dashboard.json \
  https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/dashboards/db

echo "Dashboard JSON created for instance ${AWS_INSTANCE_ID}"
echo "Dashboard UID: ${DASHBOARD_UID}"

curl https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/folders
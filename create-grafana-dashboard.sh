#!/bin/bash

# Create temporary Grafana dashboard for this instance
GAME_ENV="dev"
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region)
DASHBOARD_NAME="Game Logs - ${GAME_ENV} - ${AWS_INSTANCE_ID} - $(date +%Y-%m-%d-%H-%M-%S)"
DASHBOARD_UID="game-logs-${AWS_INSTANCE_ID}-$(date +%Y%m%d)"
FOLDER_NAME="Temporary Instances - $(date +%Y-%m-%d)"
GRAFANA_FOLDER_UID="beqw3x1oiwnb4c"

# Create dashboard JSON
cat > dashboard.json << EOF
{
  "dashboard": {
    "id": null,
    "title": "${DASHBOARD_NAME}",
    "uid": "${DASHBOARD_UID}",
    "tags": ["Cryptorun", "Streaming-logs", "${GAME_ENV}", "${AWS_REGION}"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Game Logs - ${AWS_INSTANCE_ID}",
        "type": "logs",
        "targets": [
          {
            "expr": "{aws_instance_id=\"${AWS_INSTANCE_ID}\"}",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
        "options": {
          "showTime": true,
          "showLabels": true,
          "sortOrder": "Descending"
        }
      },
      {
        "id": 2,
        "title": "Logs by File",
        "type": "logs",
        "targets": [
          {
            "expr": "{aws_instance_id=\"${AWS_INSTANCE_ID}\"} |= \"\"",
            "refId": "A"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
        "transformations": [
          {
            "id": "groupBy",
            "options": {
              "fields": {
                "filename": {
                  "aggregations": [],
                  "operation": "groupby"
                }
              }
            }
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "10s"
  },
  "folderUid": "${GRAFANA_FOLDER_UID}",
  "overwrite": true
}
EOF

GRAFANA_USER="grafana"
GRAFANA_PASS="admin"
GRAFANA_URL="grafana.monitor.rektgames.io"
# Create the dashboard via Grafana API (if credentials are available)
curl -X POST \
  -H "Content-Type: application/json" \
  -d @dashboard.json \
  https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/dashboards/db

echo "Dashboard JSON created for instance ${AWS_INSTANCE_ID}"
echo "Dashboard UID: ${DASHBOARD_UID}"

curl https://${GRAFANA_USER}:${GRAFANA_PASS}@${GRAFANA_URL}/api/folders
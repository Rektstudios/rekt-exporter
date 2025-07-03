#!/bin/bash
# Define the script working DIR
SCRIPT_DIR="$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Load environment variables from .env file
export $(grep -v '^#' $SCRIPT_DIR/.env | xargs)

openPorts () {
    # Check if ports are already open
    PORTS=(8080 9100 9080)

    echo "Running this will be opening Ports 8080, 9100 and 9080 in ufw."
    read -p "Do you want to continue? (y/n) " answer

    if [[ $answer == "y" ]]; then
        sudo ufw route allow proto tcp from any to any port 9080
        sudo ufw route allow proto tcp from any to any port 9100
        sudo ufw route allow proto tcp from any to any port 8080
        echo "Ports 8080, 9100 and 9080 opened in ufw."
    else
        echo "Operation aborted."
        exit 0
    fi
}

installLokiDriver () {
    # Step 1: Check if Loki Docker Driver is already installed
    if docker plugin ls | grep -q "loki"; then
        echo "Driver Client already running"
    fi

    # Step 3: Install the Loki Docker Driver
    docker plugin install grafana/loki-docker-driver:2.9.1 --alias loki --grant-all-permissions

    # Step 4: Check if /etc/docker/daemon.json exists and has the required content
    REQUIRED_CONTENT='{
    "debug": true,
    "log-driver": "loki",
    "log-opts": {
            "loki-url": "'$LOKI_URL'/loki/api/v1/push",
            "loki-batch-size": "400",
            "loki-external-labels": "tenant='$INSTANCE'"
        }
    }'

    if [[ -e /etc/docker/daemon.json ]]; then
        CURRENT_CONTENT=$(cat /etc/docker/daemon.json)
        if [[ "$CURRENT_CONTENT" == "$REQUIRED_CONTENT" ]]; then
            echo "Loki Docker Log driver already enabled"
            exit 1
        else
            echo "Error: /etc/docker/daemon.json exists but content is not as expected."
            exit 1
        fi
    else
        # Step 5: If the file does not exist, create it with the content
        echo "$REQUIRED_CONTENT" > /etc/docker/daemon.json
    fi

    echo "Loki Docker Driver Client installed and configured successfully!"
}

main () {
    openPorts
    installLokiDriver
}

main
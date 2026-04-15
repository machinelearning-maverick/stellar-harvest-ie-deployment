#!/usr/bin/env bash
set -euo pipefail

# Determine repo-root and deployment dir
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$ROOT_DIR/deployment"
SCRIPTS_DIR="$DEPLOY_DIR/scripts"

export PROJECT_ROOT="$(dirname "$ROOT_DIR")"

echo "Starting Kafka stack via Docker Compose..."
cd "$DEPLOY_DIR"
docker compose up -d --build

echo "Waiting for Kafka to become healthy..."
TIMEOUT=60
until docker compose ps kafka | grep -q "(healthy)"; do
  sleep 5
  TIMEOUT=$((TIMEOUT - 5))
  if [ "$TIMEOUT" -le 0 ]; then
    echo "Timed out waiting for Kafka to become healthy" >&2
    exit 1
  fi
  echo "  still waiting... (${TIMEOUT}s remaining)"
done

echo "Kafka is healthy. Creating topic(s)..."
# invoke the create-topic script from its location
"$SCRIPTS_DIR/create-topic.sh"

echo "Kafka is up and your topic(s) are ready."
echo "Kafdrop - Kafka Web UI available at http://localhost:9000/"
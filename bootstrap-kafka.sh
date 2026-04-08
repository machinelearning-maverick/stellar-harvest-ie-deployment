#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deployment"

export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Starting Kafka stack via Docker Compose…"
cd "$DEPLOY_DIR"
docker compose build producer-swpc-scheduler
docker compose build consumer-swpc
docker compose up -d

echo "Waiting for Kafka to become healthy…"
TIMEOUT=60
until docker compose ps kafka | grep -q "(healthy)"; do
  sleep 5
  TIMEOUT=$((TIMEOUT - 5))
  if [ "$TIMEOUT" -le 0 ]; then
    echo "Timed out waiting for Kafka to become healthy" >&2
    exit 1
  fi
  echo "  still waiting… (${TIMEOUT}s remaining)"
done

echo "Kafka is healthy. Topic(s) will be created by kafka-setup container."
echo "Kafdrop - Kafka Web UI available at http://localhost:9000/"

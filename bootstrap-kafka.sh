#!/usr/bin/env bash
set -euo pipefail

# Determine repo-root and deployment dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$SCRIPT_DIR/deployment"

echo "▸ Starting Kafka stack via Docker Compose…"
cd "$DEPLOY_DIR"
docker-compose up -d

echo "▸ Waiting for Kafka to become ready…"
# crude wait; replace with a proper healthcheck loop if you like
sleep 5

echo "▸ Creating topic(s)…"
# invoke the create-topic script from its location
"$DEPLOY_DIR/scripts/create-topic.sh"

echo "Kafka is up and your topic(s) are ready."

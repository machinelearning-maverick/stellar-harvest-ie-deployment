#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:?Usage: redeploy-service.sh <docker-compose-service-name>}"

# Determine the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yml"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

export PROJECT_ROOT="$(dirname "$(dirname "$DEPLOY_DIR")")"

echo "Publishing private modules to devpi..."
"$SCRIPT_DIR/publish-module.sh"

echo "Building $SERVICE (no cache)..."
cd "$DEPLOY_DIR"
docker compose build --no-cache "$SERVICE"

echo "Restarting $SERVICE..."
docker compose up -d "$SERVICE"

echo "Done. $SERVICE is redeployed."
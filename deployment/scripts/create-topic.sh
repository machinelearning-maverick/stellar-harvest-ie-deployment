#!/usr/bin/env bash
set -euo pipefail

# Determine the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yml"

: "${KAFKA_URI:=localhost:9092}"
TOPIC="${1:-stellar-harvest-ie-raw-space-weather}"
PARTITIONS="${2:-3}"
REPLICATION="${3:-1}"
RETENTION_MS="${4:-259200000}"  # 3 days

echo "Creating topic '$TOPIC' on $KAFKA_URI with $PARTITIONS partitions, $REPLICATION replicas..."
docker-compose -f "$COMPOSE_FILE" exec kafka \
  kafka-topics --create \
  --topic "$TOPIC" \
  --bootstrap-server "$KAFKA_URI" \
  --partitions "$PARTITIONS" \
  --replication-factor "$REPLICATION" \
  --config "retention.ms=$RETENTION_MS"

echo "Done."
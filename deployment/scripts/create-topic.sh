#!/usr/bin/env bash
set -euo pipefail

# Determine the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/../docker-compose.yml"

: "${KAFKA_URI:=kafka:9092}"
TOPIC="${1:-stellar-harvest-ie-raw-space-weather}"
PARTITIONS="${2:-3}"
REPLICATION="${3:-1}"
RETENTION_MS="${4:-259200000}"  # 3 days

# 1) Wait for the broker to accept connections
echo "Waiting up to 60s for Kafka at ${KAFKA_URI}…"
TIMEOUT=60
until docker-compose -f "$COMPOSE_FILE" exec -T kafka \
        kafka-topics --bootstrap-server "$KAFKA_URI" --list \
        >/dev/null 2>&1
do
  sleep 5
  TIMEOUT=$((TIMEOUT - 5))
  if [ "$TIMEOUT" -le 0 ]; then
    echo "Timed out waiting for Kafka broker to be ready" >&2
    exit 1
  fi
  echo "  still waiting… (${TIMEOUT}s remaining)"
done
echo "Kafka broker is ready!"

# 2) Create the topic only if it doesn’t exist
echo "Creating topic '$TOPIC' (if-not-exists) on $KAFKA_URI with $PARTITIONS partitions, $REPLICATION replicas..."
docker-compose -f "$COMPOSE_FILE" exec -T kafka \
  kafka-topics --create \
  --topic "$TOPIC" \
  --bootstrap-server "$KAFKA_URI" \
  --partitions "$PARTITIONS" \
  --replication-factor "$REPLICATION" \
  --config "retention.ms=$RETENTION_MS" \
  --if-not-exists

echo "Done."
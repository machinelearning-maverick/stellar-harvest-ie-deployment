# Scheduled Jobs

This document describes all scheduled jobs running in the StellarHarvest
Insight Engine. Each job runs as a dedicated service in
[`deployment/docker-compose.yml`](deployment/docker-compose.yml).

> **Scope:** recurring jobs only. One-shot init tasks (e.g., `db-init`)
> are not scheduled and are not listed here.

## Index

| Service                       | Domain   | Cadence       | Owning module                    |
|-------------------------------|----------|---------------|----------------------------------|
| `producer-swpc-scheduler`     | stellar  | every 5 min   | `stellar-harvest-ie-producers`   |
| `ml-stellar-classify-trainer` | stellar  | weekly (Sun)  | `stellar-harvest-ie-ml-stellar`  |

## Jobs

### `producer-swpc-scheduler`

Polls NOAA SWPC and publishes Kp-index records to Kafka.

- **Entrypoint:** `sh-swpc-scheduler` → `stellar_harvest_ie_producers.schedulers.swpc:main`
- **Cadence:** every 5 minutes
- **Depends on:** Kafka (`stellar-harvest-ie-raw-space-weather` topic)
- **Writes to:** Kafka topic `stellar-harvest-ie-raw-space-weather`
- **Failure mode:** skips a tick and retries on the next interval;
  no backfill
- **Logs:** `docker compose logs -f producer-swpc-scheduler`

### `ml-stellar-classify-trainer`

Retrains the Kp-index classification model and registers the result in
MLflow.

- **Entrypoint:** `sh-classify-train` → `stellar_harvest_ie_ml_stellar.schedulers.classify_train:main`
- **Cadence:** Sundays at 03:00 UTC
- **Depends on:** Postgres (reads Kp history), MLflow tracking server
- **Writes to:** MLflow model registry (`kp-classifier`)
- **Failure mode:** run is logged to MLflow as failed; model registry
  unchanged; no automatic retry until next Sunday
- **Logs:** `docker compose logs -f ml-stellar-classify-trainer`
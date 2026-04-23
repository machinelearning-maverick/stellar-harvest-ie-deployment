# Scheduled Jobs

This document describes all scheduled jobs running in the StellarHarvest
Insight Engine. Each job runs as a dedicated service in
[`deployment/docker-compose.yml`](deployment/docker-compose.yml).

> **Scope:** recurring jobs only. One-shot init tasks (e.g., `db-init`)
> are not scheduled and are not listed here.

## Index

| Service                         | Domain   | Cadence       | Owning module                    |
|---------------------------------|----------|---------------|----------------------------------|
| `producer-swpc-scheduler`       | stellar  | every N min   | `stellar-harvest-ie-producers`   |
| `ml-stellar-classify-trainer`   | stellar  | weekly        | `stellar-harvest-ie-ml-stellar`  |

## Jobs

### `producer-swpc-scheduler`

Polls NOAA SWPC and publishes Kp-index records to Kafka.

- **Entrypoint:** `sh-swpc-scheduler` → `stellar_harvest_ie_producers.schedulers.swpc_scheduler:main`
- **Cadence:** every `SCHEDULE_EVERY_MINUTES` minutes (env var)
- **On startup:** runs `job()` once immediately, then enters the schedule loop
- **Config (env):** `KAFKA_URI`, `KAFKA_TOPIC_SWPC`, `SCHEDULE_EVERY_MINUTES`
- **Writes to:** Kafka topic `stellar-harvest-ie-raw-space-weather`
- **Failure mode:** on `NoBrokersAvailable`, retries up to 5 times with a
  5-second delay; any other exception is logged and the tick is skipped.
  The loop keeps running regardless.
- **Logs:** `docker compose logs -f producer-swpc-scheduler`

### `ml-stellar-classify-trainer`

Retrains the Kp-index classification model. Will register results in
MLflow once the MLflow service is wired in.

- **Entrypoint:** `sh-classify-train` → `stellar_harvest_ie_ml_stellar.schedulers.classify_train:main`
- **Cadence:** `SCHEDULE_CLASSIFY_DAY` at `SCHEDULE_CLASSIFY_AT` (env vars,
  e.g., `sunday` at `03:00`)
- **On startup:** does **not** run on startup — training is expensive and
  shouldn't fire on every container restart. For one-off runs, invoke
  `run_classification_pipeline()` directly in a disposable container.
- **Config (env):** `SCHEDULE_CLASSIFY_DAY`, `SCHEDULE_CLASSIFY_AT`,
  plus whatever the pipeline itself reads (DB connection, MLflow URI when
  added)
- **Writes to:** MLflow model registry (once MLflow is integrated)
- **Failure mode:** the pipeline is wrapped in a catch-all `try/except`;
  failures are logged with traceback and the scheduler waits for the next
  scheduled run. No automatic retry within the same window.
- **Logs:** `docker compose logs -f ml-stellar-classify-trainer`
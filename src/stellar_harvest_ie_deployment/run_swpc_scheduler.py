import os
import time
import logging
import schedule

from stellar_harvest_ie_config.logging_config import setup_logging

setup_logging()

from kafka.errors import NoBrokersAvailable

from stellar_harvest_ie_config.utils.log_decorators import log_io
from stellar_harvest_ie_producers.stellar.swpc.producer import (
    publish_latest_planetary_kp_index,
)

logger = logging.getLogger(__name__)


@log_io()
def job():
    logger.info("Fetching NOAA SWPC and publishing to Kafka...")
    max_attempts = 5
    for attempt in range(1, max_attempts + 1):
        try:
            publish_latest_planetary_kp_index()
            logger.info("Success")
            return
        except NoBrokersAvailable as e:
            msg = (
                f"Attempt {attempt} / {max_attempts}: Kafka not ready (see stack trace)"
            )
            logger.error(msg, exc_info=True)
            time.sleep(5)
        except Exception as e:
            logger.error("Failed...", exc_info=True)


def main():
    kafka_uri = os.getenv("KAFKA_URI")
    kafka_topic = os.getenv("KAFKA_TOPIC_SWPC")
    schedule_every_minutes = os.getenv("SCHEDULE_EVERY_MINUTES")

    msg = f"SWPC scheduler starting; broker: {kafka_uri}, topic: {kafka_topic}"
    logger.info(msg)

    schedule.every(schedule_every_minutes).minutes.do(job)
    job()

    while True:
        schedule.run_pending()
        time.sleep(1)


if __name__ == "__main__":
    main()

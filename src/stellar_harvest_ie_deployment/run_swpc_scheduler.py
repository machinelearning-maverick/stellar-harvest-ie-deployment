import os
import time
import logging
import schedule

from stellar_harvest_ie_config.logging_config import setup_logging
setup_logging()

from kafka.errors import NoBrokersAvailable

from stellar_harvest_ie_config.utils.log_decorators import log_io
from stellar_harvest_ie_producers.stellar.swpc.producer import publish_swpc_record

logger = logging.getLogger(__name__)


@log_io()
def job():
    logger.info("Fetching SWPC and publishing to Kafka...")
    max_attempts = 5
    for attempt in range(1, max_attempts + 1):
        try:
            publish_swpc_record()
            logger.info("Success")
            return
        except NoBrokersAvailable as e:
            # logger.error("Attempt %s / %s: Kafka not ready (%s). Retrying in 5s...", attempt, max_attempts, e))
            msg = f"Attempt {attempt}"
            logger.error(msg, exc_info=True)
            time.sleep(5)
        except Exception as e:
            # logger.error("Failed: %s", str(e))
            logger.error("Failed...", exc_info=True)


def main():
    kafka_uri = os.getenv("KAFKA_URI")
    kafka_topic = os.getenv("KAFKA_TOPIC_SWPC")
    logger.info("SWPC scheduler starting...")
    # logger.info("SWPC scheduler starting; broker: %s, topic: %s", kafka_uri, kafka_topic)
    schedule.every(30).minutes.do(job)

    job()

    while True:
        schedule.run_pending()
        logger.debug("while True...")
        time.sleep(1)


if __name__ == "__main__":
    main()

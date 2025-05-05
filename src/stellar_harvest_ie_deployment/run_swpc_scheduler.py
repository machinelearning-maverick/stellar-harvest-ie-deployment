import os
import time
import logging
import schedule
from stellar_harvest_ie_config.utils.log_decorators import log_io
from stellar_harvest_ie_producers.stellar.swpc.producer import publish_swpc_record

logger = logging.getLogger(__name__)


@log_io()
def job():
    try:
        publish_swpc_record()
    except Exception as e:
        logger.error("Failed: %s", e)


def main():
    kafka_uri = os.getenv("KAFKA_URI")
    kafka_topic = os.getenv("KAFKA_TOPIC_SWPC")
    logger.info(
        "SWPC scheduler starting; broker: %s, topic: %s", kafka_uri, kafka_topic
    )
    schedule.every(30).minutes.do(job)

    job()

    while True:
        schedule.run_pending()
        time.sleep(1)


if __name__ == "__main__":
    main()

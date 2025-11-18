import asyncio
import os
from aiokafka import AIOKafkaConsumer
import json

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")

async def start_consumer():
    consumer = AIOKafkaConsumer(
        KAFKA_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id="notification-service-group",
    )
    await consumer.start()
    try:
        async for msg in consumer:
            data = json.loads(msg.value.decode("utf-8"))
            # Simulate notification sending
            print("Notification event:", data)
    finally:
        await consumer.stop()

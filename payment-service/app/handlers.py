import asyncio
import os
from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
import json

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")

async def process_order_event(message):
    data = json.loads(message.value.decode("utf-8"))
    event_type = data.get("event_type")
    if event_type == "order_created":
        order_id = data.get("order_id")
        # In real implementation: create payment record, decide success/failure
        result_event = {"event_type": "payment_success", "order_id": order_id}
        return result_event
    return None

async def start_consumer():
    consumer = AIOKafkaConsumer(
        KAFKA_TOPIC,
        bootstrap_servers=KAFKA_BROKER,
        group_id="payment-service-group",
    )
    producer = AIOKafkaProducer(bootstrap_servers=KAFKA_BROKER)
    await consumer.start()
    await producer.start()
    try:
        async for msg in consumer:
            res = await process_order_event(msg)
            if res:
                await producer.send_and_wait(KAFKA_TOPIC, json.dumps(res).encode("utf-8"))
    finally:
        await consumer.stop()
        await producer.stop()

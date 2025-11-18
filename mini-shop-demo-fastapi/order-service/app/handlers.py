from fastapi import APIRouter, FastAPI, HTTPException, BackgroundTasks
from .db import get_db
from pydantic import BaseModel
import os
import httpx
import json
from typing import Dict
from aiokafka import AIOKafkaProducer
import asyncio

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")
PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8081")

producer: AIOKafkaProducer = None

class OrderIn(BaseModel):
    user_id: str
    product_id: str
    quantity: int

class OrderOut(OrderIn):
    id: str
    status: str

def register_routes(app: FastAPI):
    router = APIRouter(prefix="/api/v1")

    @app.on_event("startup")
    async def start_kafka():
        global producer
        producer = AIOKafkaProducer(bootstrap_servers=KAFKA_BROKER)
        await producer.start()

    @app.on_event("shutdown")
    async def stop_kafka():
        if producer:
            await producer.stop()

    @router.post("/orders", response_model=OrderOut)
    async def create_order(order: OrderIn, background_tasks: BackgroundTasks):
        async with httpx.AsyncClient() as client:
            r = await client.get(f"{PRODUCT_SERVICE_URL}/api/v1/products/{order.product_id}")
            if r.status_code != 200:
                raise HTTPException(status_code=400, detail="product unavailable")
        db = get_db()
        order_doc = order.dict()
        order_doc["status"] = "created"
        res = await db["orders"].insert_one(order_doc)
        inserted_id = str(res.inserted_id)

        event = {"event_type": "order_created", "order_id": inserted_id, "payload": order_doc}
        if producer:
            await producer.send_and_wait(KAFKA_TOPIC, json.dumps(event).encode("utf-8"))
        return {"id": inserted_id, **order.dict(), "status": "created"}

    app.include_router(router)

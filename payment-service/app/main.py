from fastapi import FastAPI
import os
from .db import init_db
from .handlers import start_consumer
app = FastAPI(title="Payment Service")

@app.on_event("startup")
async def startup_event():
    await init_db(
        host=os.getenv("MONGO_HOST", "mongo"),
        port=int(os.getenv("MONGO_PORT", "27017")),
        db_name=os.getenv("MONGO_DB", "paymentdb"),
    )
    app.state.kafka_task = start_consumer()

@app.on_event("shutdown")
async def shutdown_event():
    task = getattr(app.state, "kafka_task", None)
    if task:
        task.cancel()

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "payment-service"}

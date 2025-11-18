from fastapi import FastAPI
import os
from .handlers import start_consumer
app = FastAPI(title="Notification Service")

@app.on_event("startup")
async def startup_event():
    app.state.kafka_task = start_consumer()

@app.on_event("shutdown")
async def shutdown_event():
    task = getattr(app.state, "kafka_task", None)
    if task:
        task.cancel()

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "notification-service"}

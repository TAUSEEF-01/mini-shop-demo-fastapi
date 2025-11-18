from fastapi import FastAPI
import os
from .db import init_db, get_db
from .handlers import register_routes

app = FastAPI(title="Order Service")

@app.on_event("startup")
async def startup_event():
    await init_db(
        host=os.getenv("MONGO_HOST", "mongo"),
        port=int(os.getenv("MONGO_PORT", "27017")),
        db_name=os.getenv("MONGO_DB", "orderdb"),
    )

register_routes(app)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "order-service"}

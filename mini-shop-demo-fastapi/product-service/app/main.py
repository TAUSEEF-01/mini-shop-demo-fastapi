from fastapi import FastAPI
import os
from .db import init_db, get_db
from .cache import init_redis, get_redis
from .handlers import register_routes

app = FastAPI(title="Product Service")

@app.on_event("startup")
async def startup_event():
    await init_db(
        host=os.getenv("MONGO_HOST", "mongo"),
        port=int(os.getenv("MONGO_PORT", "27017")),
        db_name=os.getenv("MONGO_DB", "productdb"),
    )
    await init_redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", "6379")),
    )

register_routes(app)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "product-service"}

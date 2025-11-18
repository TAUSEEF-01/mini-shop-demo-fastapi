from fastapi import FastAPI, HTTPException, Depends
import os
from .db import get_db, init_db
from .handlers import register_routes

app = FastAPI(title="User Service")

@app.on_event("startup")
async def startup_event():
    await init_db(
        host=os.getenv("MONGO_HOST", "mongo"),
        port=int(os.getenv("MONGO_PORT", "27017")),
        db_name=os.getenv("MONGO_DB", "userdb"),
    )

register_routes(app)

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "user-service"}

from fastapi import FastAPI, APIRouter, HTTPException
from .db import get_db
from .cache import get_redis
from pydantic import BaseModel
from typing import List
import json

class ProductIn(BaseModel):
    name: str
    price: float
    stock: int

class ProductOut(ProductIn):
    id: str

def register_routes(app: FastAPI):
    router = APIRouter(prefix="/api/v1")

    @router.post("/products", response_model=ProductOut)
    async def create_product(p: ProductIn):
        db = get_db()
        res = await db["products"].insert_one(p.dict())
        product = {**p.dict(), "id": str(res.inserted_id)}
        redis = get_redis()
        if redis:
            await redis.set(f"product:{product['id']}", json.dumps(product), ex=3600)
        return product

    @router.get("/products", response_model=List[ProductOut])
    async def list_products():
        db = get_db()
        cursor = db["products"].find({})
        items = []
        async for doc in cursor:
            doc["id"] = str(doc["_id"])
            items.append(doc)
        return items

    @router.get("/products/{product_id}", response_model=ProductOut)
    async def get_product(product_id: str):
        redis = get_redis()
        if redis:
            cached = await redis.get(f"product:{product_id}")
            if cached:
                return json.loads(cached)
        db = get_db()
        # NOTE: The scaffold uses string IDs for simplicity; you should convert to ObjectId when storing/reading in production.
        doc = await db["products"].find_one({"_id": product_id})
        if not doc:
            raise HTTPException(status_code=404, detail="product not found")
        doc["id"] = str(doc["_id"])
        if redis:
            await redis.set(f"product:{product_id}", json.dumps(doc), ex=3600)
        return doc

    app.include_router(router)

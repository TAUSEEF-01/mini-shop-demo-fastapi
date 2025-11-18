from fastapi import APIRouter, FastAPI, HTTPException
from .db import get_db
from pydantic import BaseModel

class UserCreate(BaseModel):
    name: str
    email: str
    password: str

class UserOut(BaseModel):
    id: str
    name: str
    email: str

def register_routes(app: FastAPI):
    router = APIRouter(prefix="/api/v1")

    @router.post("/register", response_model=UserOut)
    async def register(user: UserCreate):
        db = get_db()
        res = await db["users"].insert_one(user.dict())
        return {"id": str(res.inserted_id), "name": user.name, "email": user.email}

    @router.post("/login")
    async def login():
        # TODO: implement JWT auth
        return {"token": "TODO"}

    app.include_router(router)

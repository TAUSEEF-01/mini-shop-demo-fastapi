from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional

_client: Optional[AsyncIOMotorClient] = None
_db = None

async def init_db(host="mongo", port=27017, db_name="paymentdb"):
    global _client, _db
    uri = f"mongodb://{host}:{port}"
    _client = AsyncIOMotorClient(uri)
    _db = _client[db_name]

def get_db():
    return _db

import aioredis
from typing import Optional

_redis: Optional[aioredis.Redis] = None

async def init_redis(host="redis", port=6379):
    global _redis
    _redis = aioredis.from_url(f"redis://{host}:{port}", encoding="utf-8", decode_responses=True)

def get_redis():
    return _redis

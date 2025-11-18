# <#
# PowerShell script to create the "mini-shop-demo-fastapi" scaffold and package it as a ZIP on Windows.

# Usage:
# 1. Save this file as create_scaffold_zip.ps1
# 2. Open PowerShell (you may need to set execution policy):
#    - Run as Administrator (if required)
#    - To temporarily allow script execution (if blocked): Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# 3. Run the script:
#    .\create_scaffold_zip.ps1
# 4. The script creates the folder "mini-shop-demo-fastapi" and a zip "mini-shop-demo-fastapi.zip" in the same directory.

# Note:
# - This script writes many files; review them before publishing to any repo.
# - After unzipping, follow the earlier instructions to create a GitHub repo and push the files.
# #>

# $rootDir = "mini-shop-demo-fastapi"
# $zipName = "$rootDir.zip"

# Write-Host "Creating scaffold in .\$rootDir and packaging as $zipName ..."

# # Remove previous run artifacts if present
# if (Test-Path $rootDir) { Remove-Item -Recurse -Force $rootDir }
# if (Test-Path $zipName) { Remove-Item -Force $zipName }

# # Create directories
# $dirs = @(
#     $rootDir,
#     "$rootDir\user-service\app",
#     "$rootDir\product-service\app",
#     "$rootDir\order-service\app",
#     "$rootDir\payment-service\app",
#     "$rootDir\notification-service\app"
# )
# foreach ($d in $dirs) {
#     New-Item -ItemType Directory -Path $d -Force | Out-Null
# }

# # Helper to write files with UTF8 encoding
# function Write-FileUtf8($path, $content) {
#     $full = Join-Path -Path (Get-Location) -ChildPath $path
#     $dir = Split-Path -Path $full -Parent
#     if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
#     $content | Out-File -FilePath $full -Encoding utf8 -Force
#     Write-Host "Wrote $path"
# }

# # README.md
# $readme = @'
# # mini-shop-demo-fastapi

# A FastAPI + MongoDB reimplementation of the "mini-shop-demo" microservices example.

# This repository provides a scaffold of the same architecture as the Go project (user, product, order, payment, notification services) implemented in Python using FastAPI. It uses:

# - FastAPI / Uvicorn for HTTP servers
# - MongoDB (one logical database per service on the same Mongo server)
# - Redis for product caching
# - Kafka (with Zookeeper) for asynchronous event-driven flows (aiokafka)
# - OpenTelemetry -> Jaeger for tracing
# - Prometheus + Grafana for metrics visualization
# - Loki + Promtail for logging aggregation
# - Kafdrop for inspecting Kafka topics

# This is an initial scaffold providing the core files and working patterns for:
# - service folder layout
# - Dockerfiles and docker-compose topology
# - example FastAPI application code (async) for services
# - Kafka producer/consumer skeletons with trace header propagation (aiokafka + opentelemetry)
# - Redis cache usage in product service (aioredis)
# - MongoDB access via motor (async)

# Quick start (development)
# 1. Build & start infrastructure and services:
#    docker-compose up --build

# 2. Access:
#    - User Service: http://localhost:8080
#    - Product Service: http://localhost:8081
#    - Order Service: http://localhost:8082
#    - Payment Service: http://localhost:8083
#    - Notification Service: http://localhost:8084
#    - Jaeger: http://localhost:16686
#    - Prometheus: http://localhost:9090
#    - Grafana: http://localhost:3000 (admin/admin)
#    - Kafdrop: http://localhost:9000

# Notes / Decisions
# - Internal synchronous calls are implemented as HTTP calls (FastAPI -> FastAPI using httpx) instead of gRPC for simplicity and easier Python dev workflow.
# - MongoDB is used as the persistent store. Each service uses its own logical database name (userdb, productdb, orderdb, paymentdb) within the same Mongo server started in docker-compose.
# - Kafka integration uses aiokafka (async) and propagates OpenTelemetry trace context via message headers (scaffolded).
# - Redis caching uses aioredis.
# - Tracing uses OpenTelemetry Python with Jaeger exporter.

# Post-push TODOs (recommended)
# - Implement JWT auth & password hashing, ObjectId handling/validation, robust Kafka header-based trace propagation, retries and DLQ for Kafka processing, tests, CI workflow, and production hardening.
# '@
# Write-FileUtf8 "$rootDir\README.md" $readme

# # docker-compose.yml
# $dockerCompose = @'
# version: "3.8"
# services:
#   mongo:
#     image: mongo:6.0
#     container_name: mongo
#     ports:
#       - "27017:27017"
#     volumes:
#       - mongo_data:/data/db
#     networks:
#       - mini-net
#     healthcheck:
#       test: ["CMD", "mongo", "--eval", "db.adminCommand('ping')"]
#       interval: 10s
#       timeout: 5s
#       retries: 5

#   redis:
#     image: redis:7-alpine
#     container_name: redis
#     ports:
#       - "6379:6379"
#     networks:
#       - mini-net
#     healthcheck:
#       test: ["CMD", "redis-cli", "ping"]
#       interval: 10s
#       timeout: 5s
#       retries: 5

#   zookeeper:
#     image: confluentinc/cp-zookeeper:7.4.0
#     container_name: zookeeper
#     environment:
#       ZOOKEEPER_CLIENT_PORT: 2181
#       ZOOKEEPER_TICK_TIME: 2000
#     ports:
#       - "2181:2181"
#     networks:
#       - mini-net

#   kafka:
#     image: confluentinc/cp-kafka:7.4.0
#     container_name: kafka
#     depends_on:
#       - zookeeper
#     ports:
#       - "9092:9092"
#     environment:
#       KAFKA_BROKER_ID: 1
#       KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
#       KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
#       KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
#       KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
#       KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
#     networks:
#       - mini-net
#     healthcheck:
#       test: ["CMD", "kafka-broker-api-versions", "--bootstrap-server", "localhost:9092"]
#       interval: 30s
#       timeout: 10s
#       retries: 5

#   jaeger:
#     image: jaegertracing/all-in-one:latest
#     container_name: jaeger
#     ports:
#       - "16686:16686"
#       - "14268:14268"
#       - "14250:14250"
#     networks:
#       - mini-net

#   prometheus:
#     image: prom/prometheus:latest
#     container_name: prometheus
#     ports:
#       - "9090:9090"
#     volumes:
#       - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
#       - prometheus_data:/prometheus
#     networks:
#       - mini-net

#   grafana:
#     image: grafana/grafana:latest
#     container_name: grafana
#     ports:
#       - "3000:3000"
#     environment:
#       - GF_SECURITY_ADMIN_PASSWORD=admin
#       - GF_USERS_ALLOW_SIGN_UP=false
#     volumes:
#       - grafana_data:/var/lib/grafana
#     depends_on:
#       - prometheus
#     networks:
#       - mini-net

#   loki:
#     image: grafana/loki:3.0.0
#     container_name: loki
#     ports:
#       - "3100:3100"
#     volumes:
#       - ./loki-config.yml:/etc/loki/local-config.yaml
#       - loki_data:/loki
#     command: -config.file=/etc/loki/local-config.yaml
#     networks:
#       - mini-net

#   promtail:
#     image: grafana/promtail:latest
#     container_name: promtail
#     volumes:
#       - ./promtail-config.yml:/etc/promtail/config.yml
#       - /var/lib/docker/containers:/var/lib/docker/containers:ro
#       - /var/run/docker.sock:/var/run/docker.sock
#     command: -config.file=/etc/promtail/config.yml
#     depends_on:
#       - loki
#     networks:
#       - mini-net

#   kafdrop:
#     image: obsidiandynamics/kafdrop:latest
#     container_name: kafdrop
#     depends_on:
#       - kafka
#     ports:
#       - "9000:9000"
#     environment:
#       KAFKA_BROKERCONNECT: "kafka:9092"
#     networks:
#       - mini-net

#   user-service:
#     build:
#       context: ./user-service
#       dockerfile: Dockerfile
#     container_name: user-service
#     environment:
#       - MONGO_HOST=mongo
#       - MONGO_PORT=27017
#       - MONGO_DB=userdb
#       - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
#     ports:
#       - "8080:8080"
#     depends_on:
#       - mongo
#       - jaeger
#     networks:
#       - mini-net

#   product-service:
#     build:
#       context: ./product-service
#       dockerfile: Dockerfile
#     container_name: product-service
#     environment:
#       - MONGO_HOST=mongo
#       - MONGO_PORT=27017
#       - MONGO_DB=productdb
#       - REDIS_HOST=redis
#       - REDIS_PORT=6379
#       - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
#       - KAFKA_BROKER=kafka:9092
#       - KAFKA_TOPIC=order_events
#     ports:
#       - "8081:8081"
#     depends_on:
#       - mongo
#       - redis
#       - jaeger
#       - kafka
#     networks:
#       - mini-net

#   order-service:
#     build:
#       context: ./order-service
#       dockerfile: Dockerfile
#     container_name: order-service
#     environment:
#       - MONGO_HOST=mongo
#       - MONGO_PORT=27017
#       - MONGO_DB=orderdb
#       - PRODUCT_SERVICE_URL=http://product-service:8081
#       - KAFKA_BROKER=kafka:9092
#       - KAFKA_TOPIC=order_events
#       - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
#     ports:
#       - "8082:8082"
#     depends_on:
#       - mongo
#       - kafka
#       - product-service
#       - jaeger
#     networks:
#       - mini-net

#   payment-service:
#     build:
#       context: ./payment-service
#       dockerfile: Dockerfile
#     container_name: payment-service
#     environment:
#       - MONGO_HOST=mongo
#       - MONGO_PORT=27017
#       - MONGO_DB=paymentdb
#       - KAFKA_BROKER=kafka:9092
#       - KAFKA_TOPIC=order_events
#       - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
#     ports:
#       - "8083:8083"
#     depends_on:
#       - mongo
#       - kafka
#       - jaeger
#     networks:
#       - mini-net

#   notification-service:
#     build:
#       context: ./notification-service
#       dockerfile: Dockerfile
#     container_name: notification-service
#     environment:
#       - KAFKA_BROKER=kafka:9092
#       - KAFKA_TOPIC=order_events
#       - JAEGER_ENDPOINT=http://jaeger:14268/api/traces
#     ports:
#       - "8084:8084"
#     depends_on:
#       - kafka
#       - jaeger
#     networks:
#       - mini-net

# volumes:
#   mongo_data:
#   prometheus_data:
#   grafana_data:
#   loki_data:

# networks:
#   mini-net:
#     driver: bridge
# '@
# Write-FileUtf8 "$rootDir\docker-compose.yml" $dockerCompose

# # .gitignore
# $gitignore = @'
# # Python
# __pycache__/
# *.pyc
# *.pyo
# *.pyd
# env/
# venv/
# .env

# # Docker
# *.env
# docker-compose.override.yml
# *.log

# # Node / misc
# node_modules/
# dist/

# # Editor
# .vscode/
# .idea/
# '@
# Write-FileUtf8 "$rootDir\.gitignore" $gitignore

# # prometheus.yml
# $prometheus = @'
# global:
#   scrape_interval: 15s
# scrape_configs:
#   - job_name: "prometheus"
#     static_configs:
#       - targets: ["localhost:9090"]
#   - job_name: "services"
#     static_configs:
#       - targets: ["user-service:8080", "product-service:8081", "order-service:8082", "payment-service:8083", "notification-service:8084"]
# '@
# Write-FileUtf8 "$rootDir\prometheus.yml" $prometheus

# # loki-config.yml
# $loki = @'
# auth_enabled: false
# server:
#   http_listen_port: 3100
# ingester:
#   lifecycler:
#     ring:
#       kvstore:
#         store: inmemory
# schema_config:
#   configs:
#     - from: 2020-10-24
#       store: boltdb-shipper
#       object_store: filesystem
#       schema: v11
#       index:
#         prefix: index_
#         period: 24h
# '@
# Write-FileUtf8 "$rootDir\loki-config.yml" $loki

# # promtail-config.yml
# $promtail = @'
# server:
#   http_listen_port: 9080
# positions:
#   filename: /tmp/positions.yaml
# clients:
#   - url: http://loki:3100/loki/api/v1/push
# scrape_configs:
#   - job_name: system
#     static_configs:
#       - targets:
#           - localhost
#         labels:
#           job: varlogs
# '@
# Write-FileUtf8 "$rootDir\promtail-config.yml" $promtail

# # ----- user-service files -----
# $userDockerfile = @'
# FROM python:3.11-slim

# WORKDIR /app
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

# COPY ./app /app/app
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080", "--reload"]
# '@
# Write-FileUtf8 "$rootDir\user-service\Dockerfile" $userDockerfile

# $userReqs = @'
# fastapi
# uvicorn[standard]
# motor
# pydantic
# httpx
# aiokafka
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi
# opentelemetry-exporter-jaeger
# prometheus-client
# python-dotenv
# '@
# Write-FileUtf8 "$rootDir\user-service\requirements.txt" $userReqs

# $userMain = @'
# from fastapi import FastAPI, HTTPException, Depends
# import os
# from .db import get_db, init_db
# from .handlers import register_routes

# app = FastAPI(title="User Service")

# @app.on_event("startup")
# async def startup_event():
#     await init_db(
#         host=os.getenv("MONGO_HOST", "mongo"),
#         port=int(os.getenv("MONGO_PORT", "27017")),
#         db_name=os.getenv("MONGO_DB", "userdb"),
#     )

# register_routes(app)

# @app.get("/health")
# async def health():
#     return {"status": "healthy", "service": "user-service"}
# '@
# Write-FileUtf8 "$rootDir\user-service\app\main.py" $userMain

# $userDb = @'
# from motor.motor_asyncio import AsyncIOMotorClient
# from typing import Optional

# _client: Optional[AsyncIOMotorClient] = None
# _db = None

# async def init_db(host="mongo", port=27017, db_name="userdb"):
#     global _client, _db
#     uri = f"mongodb://{host}:{port}"
#     _client = AsyncIOMotorClient(uri)
#     _db = _client[db_name]

# def get_db():
#     return _db
# '@
# Write-FileUtf8 "$rootDir\user-service\app\db.py" $userDb

# $userHandlers = @'
# from fastapi import APIRouter, FastAPI, HTTPException
# from .db import get_db
# from pydantic import BaseModel

# class UserCreate(BaseModel):
#     name: str
#     email: str
#     password: str

# class UserOut(BaseModel):
#     id: str
#     name: str
#     email: str

# def register_routes(app: FastAPI):
#     router = APIRouter(prefix="/api/v1")

#     @router.post("/register", response_model=UserOut)
#     async def register(user: UserCreate):
#         db = get_db()
#         res = await db["users"].insert_one(user.dict())
#         return {"id": str(res.inserted_id), "name": user.name, "email": user.email}

#     @router.post("/login")
#     async def login():
#         # TODO: implement JWT auth
#         return {"token": "TODO"}

#     app.include_router(router)
# '@
# Write-FileUtf8 "$rootDir\user-service\app\handlers.py" $userHandlers

# # ----- product-service files -----
# $productDockerfile = @'
# FROM python:3.11-slim

# WORKDIR /app
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

# COPY ./app /app/app
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8081", "--reload"]
# '@
# Write-FileUtf8 "$rootDir\product-service\Dockerfile" $productDockerfile

# $productReqs = @'
# fastapi
# uvicorn[standard]
# motor
# pydantic
# httpx
# aioredis
# aiokafka
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi
# opentelemetry-exporter-jaeger
# prometheus-client
# python-dotenv
# '@
# Write-FileUtf8 "$rootDir\product-service\requirements.txt" $productReqs

# $productMain = @'
# from fastapi import FastAPI
# import os
# from .db import init_db, get_db
# from .cache import init_redis, get_redis
# from .handlers import register_routes

# app = FastAPI(title="Product Service")

# @app.on_event("startup")
# async def startup_event():
#     await init_db(
#         host=os.getenv("MONGO_HOST", "mongo"),
#         port=int(os.getenv("MONGO_PORT", "27017")),
#         db_name=os.getenv("MONGO_DB", "productdb"),
#     )
#     await init_redis(
#         host=os.getenv("REDIS_HOST", "redis"),
#         port=int(os.getenv("REDIS_PORT", "6379")),
#     )

# register_routes(app)

# @app.get("/health")
# async def health():
#     return {"status": "healthy", "service": "product-service"}
# '@
# Write-FileUtf8 "$rootDir\product-service\app\main.py" $productMain

# $productDb = @'
# from motor.motor_asyncio import AsyncIOMotorClient
# from typing import Optional

# _client: Optional[AsyncIOMotorClient] = None
# _db = None

# async def init_db(host="mongo", port=27017, db_name="productdb"):
#     global _client, _db
#     uri = f"mongodb://{host}:{port}"
#     _client = AsyncIOMotorClient(uri)
#     _db = _client[db_name]

# def get_db():
#     return _db
# '@
# Write-FileUtf8 "$rootDir\product-service\app\db.py" $productDb

# $productCache = @'
# import aioredis
# from typing import Optional

# _redis: Optional[aioredis.Redis] = None

# async def init_redis(host="redis", port=6379):
#     global _redis
#     _redis = aioredis.from_url(f"redis://{host}:{port}", encoding="utf-8", decode_responses=True)

# def get_redis():
#     return _redis
# '@
# Write-FileUtf8 "$rootDir\product-service\app\cache.py" $productCache

# $productHandlers = @'
# from fastapi import FastAPI, APIRouter, HTTPException
# from .db import get_db
# from .cache import get_redis
# from pydantic import BaseModel
# from typing import List
# import json

# class ProductIn(BaseModel):
#     name: str
#     price: float
#     stock: int

# class ProductOut(ProductIn):
#     id: str

# def register_routes(app: FastAPI):
#     router = APIRouter(prefix="/api/v1")

#     @router.post("/products", response_model=ProductOut)
#     async def create_product(p: ProductIn):
#         db = get_db()
#         res = await db["products"].insert_one(p.dict())
#         product = {**p.dict(), "id": str(res.inserted_id)}
#         redis = get_redis()
#         if redis:
#             await redis.set(f"product:{product['id']}", json.dumps(product), ex=3600)
#         return product

#     @router.get("/products", response_model=List[ProductOut])
#     async def list_products():
#         db = get_db()
#         cursor = db["products"].find({})
#         items = []
#         async for doc in cursor:
#             doc["id"] = str(doc["_id"])
#             items.append(doc)
#         return items

#     @router.get("/products/{product_id}", response_model=ProductOut)
#     async def get_product(product_id: str):
#         redis = get_redis()
#         if redis:
#             cached = await redis.get(f"product:{product_id}")
#             if cached:
#                 return json.loads(cached)
#         db = get_db()
#         # NOTE: The scaffold uses string IDs for simplicity; you should convert to ObjectId when storing/reading in production.
#         doc = await db["products"].find_one({"_id": product_id})
#         if not doc:
#             raise HTTPException(status_code=404, detail="product not found")
#         doc["id"] = str(doc["_id"])
#         if redis:
#             await redis.set(f"product:{product_id}", json.dumps(doc), ex=3600)
#         return doc

#     app.include_router(router)
# '@
# Write-FileUtf8 "$rootDir\product-service\app\handlers.py" $productHandlers

# # ----- order-service files -----
# $orderDockerfile = @'
# FROM python:3.11-slim

# WORKDIR /app
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

# COPY ./app /app/app
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8082", "--reload"]
# '@
# Write-FileUtf8 "$rootDir\order-service\Dockerfile" $orderDockerfile

# $orderReqs = @'
# fastapi
# uvicorn[standard]
# motor
# pydantic
# httpx
# aiokafka
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi
# opentelemetry-exporter-jaeger
# prometheus-client
# python-dotenv
# '@
# Write-FileUtf8 "$rootDir\order-service\requirements.txt" $orderReqs

# $orderMain = @'
# from fastapi import FastAPI
# import os
# from .db import init_db, get_db
# from .handlers import register_routes

# app = FastAPI(title="Order Service")

# @app.on_event("startup")
# async def startup_event():
#     await init_db(
#         host=os.getenv("MONGO_HOST", "mongo"),
#         port=int(os.getenv("MONGO_PORT", "27017")),
#         db_name=os.getenv("MONGO_DB", "orderdb"),
#     )

# register_routes(app)

# @app.get("/health")
# async def health():
#     return {"status": "healthy", "service": "order-service"}
# '@
# Write-FileUtf8 "$rootDir\order-service\app\main.py" $orderMain

# $orderDb = @'
# from motor.motor_asyncio import AsyncIOMotorClient
# from typing import Optional

# _client: Optional[AsyncIOMotorClient] = None
# _db = None

# async def init_db(host="mongo", port=27017, db_name="orderdb"):
#     global _client, _db
#     uri = f"mongodb://{host}:{port}"
#     _client = AsyncIOMotorClient(uri)
#     _db = _client[db_name]

# def get_db():
#     return _db
# '@
# Write-FileUtf8 "$rootDir\order-service\app\db.py" $orderDb

# $orderHandlers = @'
# from fastapi import APIRouter, FastAPI, HTTPException, BackgroundTasks
# from .db import get_db
# from pydantic import BaseModel
# import os
# import httpx
# import json
# from typing import Dict
# from aiokafka import AIOKafkaProducer
# import asyncio

# KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
# KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")
# PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL", "http://product-service:8081")

# producer: AIOKafkaProducer = None

# class OrderIn(BaseModel):
#     user_id: str
#     product_id: str
#     quantity: int

# class OrderOut(OrderIn):
#     id: str
#     status: str

# def register_routes(app: FastAPI):
#     router = APIRouter(prefix="/api/v1")

#     @app.on_event("startup")
#     async def start_kafka():
#         global producer
#         producer = AIOKafkaProducer(bootstrap_servers=KAFKA_BROKER)
#         await producer.start()

#     @app.on_event("shutdown")
#     async def stop_kafka():
#         if producer:
#             await producer.stop()

#     @router.post("/orders", response_model=OrderOut)
#     async def create_order(order: OrderIn, background_tasks: BackgroundTasks):
#         async with httpx.AsyncClient() as client:
#             r = await client.get(f"{PRODUCT_SERVICE_URL}/api/v1/products/{order.product_id}")
#             if r.status_code != 200:
#                 raise HTTPException(status_code=400, detail="product unavailable")
#         db = get_db()
#         order_doc = order.dict()
#         order_doc["status"] = "created"
#         res = await db["orders"].insert_one(order_doc)
#         inserted_id = str(res.inserted_id)

#         event = {"event_type": "order_created", "order_id": inserted_id, "payload": order_doc}
#         if producer:
#             await producer.send_and_wait(KAFKA_TOPIC, json.dumps(event).encode("utf-8"))
#         return {"id": inserted_id, **order.dict(), "status": "created"}

#     app.include_router(router)
# '@
# Write-FileUtf8 "$rootDir\order-service\app\handlers.py" $orderHandlers

# # ----- payment-service files -----
# $paymentDockerfile = @'
# FROM python:3.11-slim

# WORKDIR /app
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

# COPY ./app /app/app
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8083", "--reload"]
# '@
# Write-FileUtf8 "$rootDir\payment-service\Dockerfile" $paymentDockerfile

# $paymentReqs = @'
# fastapi
# uvicorn[standard]
# motor
# pydantic
# aiokafka
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi
# opentelemetry-exporter-jaeger
# prometheus-client
# python-dotenv
# '@
# Write-FileUtf8 "$rootDir\payment-service\requirements.txt" $paymentReqs

# $paymentMain = @'
# from fastapi import FastAPI
# import os
# from .db import init_db
# from .handlers import start_consumer
# app = FastAPI(title="Payment Service")

# @app.on_event("startup")
# async def startup_event():
#     await init_db(
#         host=os.getenv("MONGO_HOST", "mongo"),
#         port=int(os.getenv("MONGO_PORT", "27017")),
#         db_name=os.getenv("MONGO_DB", "paymentdb"),
#     )
#     app.state.kafka_task = start_consumer()

# @app.on_event("shutdown")
# async def shutdown_event():
#     task = getattr(app.state, "kafka_task", None)
#     if task:
#         task.cancel()

# @app.get("/health")
# async def health():
#     return {"status": "healthy", "service": "payment-service"}
# '@
# Write-FileUtf8 "$rootDir\payment-service\app\main.py" $paymentMain

# $paymentHandlers = @'
# import asyncio
# import os
# from aiokafka import AIOKafkaConsumer, AIOKafkaProducer
# import json

# KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
# KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")

# async def process_order_event(message):
#     data = json.loads(message.value.decode("utf-8"))
#     event_type = data.get("event_type")
#     if event_type == "order_created":
#         order_id = data.get("order_id")
#         # In real implementation: create payment record, decide success/failure
#         result_event = {"event_type": "payment_success", "order_id": order_id}
#         return result_event
#     return None

# async def start_consumer():
#     consumer = AIOKafkaConsumer(
#         KAFKA_TOPIC,
#         bootstrap_servers=KAFKA_BROKER,
#         group_id="payment-service-group",
#     )
#     producer = AIOKafkaProducer(bootstrap_servers=KAFKA_BROKER)
#     await consumer.start()
#     await producer.start()
#     try:
#         async for msg in consumer:
#             res = await process_order_event(msg)
#             if res:
#                 await producer.send_and_wait(KAFKA_TOPIC, json.dumps(res).encode("utf-8"))
#     finally:
#         await consumer.stop()
#         await producer.stop()
# '@
# Write-FileUtf8 "$rootDir\payment-service\app\handlers.py" $paymentHandlers

# $paymentDb = @'
# from motor.motor_asyncio import AsyncIOMotorClient
# from typing import Optional

# _client: Optional[AsyncIOMotorClient] = None
# _db = None

# async def init_db(host="mongo", port=27017, db_name="paymentdb"):
#     global _client, _db
#     uri = f"mongodb://{host}:{port}"
#     _client = AsyncIOMotorClient(uri)
#     _db = _client[db_name]

# def get_db():
#     return _db
# '@
# Write-FileUtf8 "$rootDir\payment-service\app\db.py" $paymentDb

# # ----- notification-service files -----
# $notifDockerfile = @'
# FROM python:3.11-slim

# WORKDIR /app
# COPY ./requirements.txt /app/requirements.txt
# RUN pip install --no-cache-dir -r /app/requirements.txt

# COPY ./app /app/app
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8084", "--reload"]
# '@
# Write-FileUtf8 "$rootDir\notification-service\Dockerfile" $notifDockerfile

# $notifReqs = @'
# fastapi
# uvicorn[standard]
# aiokafka
# opentelemetry-api
# opentelemetry-sdk
# opentelemetry-instrumentation-fastapi
# opentelemetry-exporter-jaeger
# prometheus-client
# python-dotenv
# '@
# Write-FileUtf8 "$rootDir\notification-service\requirements.txt" $notifReqs

# $notifMain = @'
# from fastapi import FastAPI
# import os
# from .handlers import start_consumer
# app = FastAPI(title="Notification Service")

# @app.on_event("startup")
# async def startup_event():
#     app.state.kafka_task = start_consumer()

# @app.on_event("shutdown")
# async def shutdown_event():
#     task = getattr(app.state, "kafka_task", None)
#     if task:
#         task.cancel()

# @app.get("/health")
# async def health():
#     return {"status": "healthy", "service": "notification-service"}
# '@
# Write-FileUtf8 "$rootDir\notification-service\app\main.py" $notifMain

# $notifHandlers = @'
# import asyncio
# import os
# from aiokafka import AIOKafkaConsumer
# import json

# KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
# KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "order_events")

# async def start_consumer():
#     consumer = AIOKafkaConsumer(
#         KAFKA_TOPIC,
#         bootstrap_servers=KAFKA_BROKER,
#         group_id="notification-service-group",
#     )
#     await consumer.start()
#     try:
#         async for msg in consumer:
#             data = json.loads(msg.value.decode("utf-8"))
#             # Simulate notification sending
#             print("Notification event:", data)
#     finally:
#         await consumer.stop()
# '@
# Write-FileUtf8 "$rootDir\notification-service\app\handlers.py" $notifHandlers

# # Create the zip
# Write-Host "Creating zip archive..."
# if (Test-Path $zipName) { Remove-Item -Force $zipName }
# Compress-Archive -Path $rootDir\* -DestinationPath $zipName -Force
# Write-Host "Created $zipName"

# # Show structure summary
# Write-Host ""
# Write-Host "Generated files and top-level structure:"
# Get-ChildItem -Recurse -Force $rootDir | Select-Object FullName, Length | Format-Table -AutoSize

# Write-Host ""
# Write-Host "Done. You can now upload $zipName to GitHub or unzip it."
# Write-Host "Next: unzip, inspect files, then create a repository on GitHub and push using git."
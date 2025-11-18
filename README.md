# mini-shop-demo-fastapi

A FastAPI + MongoDB reimplementation of the "mini-shop-demo" microservices example.

This repository provides a scaffold of the same architecture as the Go project (user, product, order, payment, notification services) implemented in Python using FastAPI. It uses:

- FastAPI / Uvicorn for HTTP servers
- MongoDB (one logical database per service on the same Mongo server)
- Redis for product caching
- Kafka (with Zookeeper) for asynchronous event-driven flows (aiokafka)
- OpenTelemetry -> Jaeger for tracing
- Prometheus + Grafana for metrics visualization
- Loki + Promtail for logging aggregation
- Kafdrop for inspecting Kafka topics

This is an initial scaffold providing the core files and working patterns for:
- service folder layout
- Dockerfiles and docker-compose topology
- example FastAPI application code (async) for services
- Kafka producer/consumer skeletons with trace header propagation (aiokafka + opentelemetry)
- Redis cache usage in product service (aioredis)
- MongoDB access via motor (async)

Quick start (development)
1. Build & start infrastructure and services:
   docker-compose up --build

2. Access:
   - User Service: http://localhost:8080
   - Product Service: http://localhost:8081
   - Order Service: http://localhost:8082
   - Payment Service: http://localhost:8083
   - Notification Service: http://localhost:8084
   - Jaeger: http://localhost:16686
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)
   - Kafdrop: http://localhost:9000

Notes / Decisions
- Internal synchronous calls are implemented as HTTP calls (FastAPI -> FastAPI using httpx) instead of gRPC for simplicity and easier Python dev workflow.
- MongoDB is used as the persistent store. Each service uses its own logical database name (userdb, productdb, orderdb, paymentdb) within the same Mongo server started in docker-compose.
- Kafka integration uses aiokafka (async) and propagates OpenTelemetry trace context via message headers (scaffolded).
- Redis caching uses aioredis.
- Tracing uses OpenTelemetry Python with Jaeger exporter.

Post-push TODOs (recommended)
- Implement JWT auth & password hashing, ObjectId handling/validation, robust Kafka header-based trace propagation, retries and DLQ for Kafka processing, tests, CI workflow, and production hardening.

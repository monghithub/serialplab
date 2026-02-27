# Tarea: Crear Dockerfiles stub y perfil app

## Issue: #1
## Subtarea: 2 de 2

## Objetivo

Crear 6 ficheros: el `docker-compose.yml` COMPLETO (con perfiles infra + app) y 5 Dockerfiles stub.

## Ficheros a crear

- `docker-compose.yml` (fichero COMPLETO — incluye infra y app)
- `frontend-angular/Dockerfile`
- `service-springboot/Dockerfile`
- `service-quarkus/Dockerfile`
- `service-go/Dockerfile`
- `service-node/Dockerfile`

## Contexto

**CRÍTICO: NO incluir `version:` en el docker-compose.yml.** Usamos Docker Compose V2 (Compose Spec). El fichero debe empezar directamente con `services:`.

### docker-compose.yml COMPLETO esperado

Genera este fichero EXACTO como `docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:16
    profiles: ["infra"]
    environment:
      POSTGRES_USER: serialplab
      POSTGRES_PASSWORD: serialplab
      POSTGRES_DB: serialplab
    ports:
      - "11010:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U serialplab"]
      interval: 5s
      timeout: 5s
      retries: 5

  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    profiles: ["infra"]
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
      - "11020:2181"

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    profiles: ["infra"]
    depends_on:
      zookeeper:
        condition: service_started
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://localhost:11021
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    ports:
      - "11021:9092"

  rabbitmq:
    image: rabbitmq:management
    profiles: ["infra"]
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "11022:5672"
      - "11023:15672"
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nats:
    image: nats:latest
    profiles: ["infra"]
    command: ["--js", "--http_port", "8222"]
    ports:
      - "11024:4222"
      - "11025:8222"

  apicurio-registry:
    image: apicurio/apicurio-registry:2.6.2.Final
    profiles: ["infra"]
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      REGISTRY_STORAGE_KIND: sql
      REGISTRY_STORAGE_SQL_KIND: postgresql
      REGISTRY_DATASOURCE_URL: jdbc:postgresql://postgres:5432/serialplab
      REGISTRY_DATASOURCE_USERNAME: serialplab
      REGISTRY_DATASOURCE_PASSWORD: serialplab
    ports:
      - "11011:8080"

  frontend-angular:
    build: ./frontend-angular
    profiles: ["app"]
    ports:
      - "11000:11000"
    depends_on:
      - service-springboot
      - service-quarkus
      - service-go
      - service-node

  service-springboot:
    build: ./service-springboot
    profiles: ["app"]
    ports:
      - "11001:11001"
    depends_on:
      postgres:
        condition: service_healthy

  service-quarkus:
    build: ./service-quarkus
    profiles: ["app"]
    ports:
      - "11002:11002"
    depends_on:
      postgres:
        condition: service_healthy

  service-go:
    build: ./service-go
    profiles: ["app"]
    ports:
      - "11003:11003"
    depends_on:
      postgres:
        condition: service_healthy

  service-node:
    build: ./service-node
    profiles: ["app"]
    ports:
      - "11004:11004"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres-data:
```

### Dockerfiles stub

Cada Dockerfile usa `python:3-alpine` con un HTTP server inline. Genera 5 Dockerfiles idénticos excepto por el puerto:

| Servicio | Puerto | Ruta |
|----------|--------|------|
| frontend-angular | 11000 | `frontend-angular/Dockerfile` |
| service-springboot | 11001 | `service-springboot/Dockerfile` |
| service-quarkus | 11002 | `service-quarkus/Dockerfile` |
| service-go | 11003 | `service-go/Dockerfile` |
| service-node | 11004 | `service-node/Dockerfile` |

Ejemplo para service-springboot (puerto 11001):
```dockerfile
FROM python:3-alpine
EXPOSE 11001
CMD ["python", "-c", "from http.server import HTTPServer, BaseHTTPRequestHandler; import json\nclass H(BaseHTTPRequestHandler):\n def do_GET(self):\n  self.send_response(200)\n  self.send_header('Content-Type','application/json')\n  self.end_headers()\n  self.wfile.write(json.dumps({'status':'ok'}).encode())\nHTTPServer(('',11001),H).serve_forever()"]
```

## Criterios de aceptación

- [ ] 5 directorios creados con su Dockerfile
- [ ] `docker compose --profile infra --profile app config` valida sin errores

## Validación

```bash
docker compose --profile infra --profile app config
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados, INCLUSO si la validación falla.

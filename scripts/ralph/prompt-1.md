# Tarea: Crear docker-compose.yml con perfil infra

## Issue: #1
## Subtarea: 1 de 2

## Objetivo

Crear `docker-compose.yml` en la raíz del proyecto con el perfil `infra` que levante todos los servicios de infraestructura: PostgreSQL, ZooKeeper, Kafka, RabbitMQ, NATS y Apicurio Registry.

## Ficheros a crear/modificar

- `docker-compose.yml`

## Contexto

Configuración exacta de cada servicio según las specs:

### PostgreSQL 16
```yaml
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
```

### ZooKeeper (dependencia de Kafka)
```yaml
zookeeper:
  image: confluentinc/cp-zookeeper:7.6.0
  profiles: ["infra"]
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181
  ports:
    - "11020:2181"
```

### Apache Kafka
```yaml
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
```

### RabbitMQ
```yaml
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
```

### NATS
```yaml
nats:
  image: nats:latest
  profiles: ["infra"]
  command: ["--js", "--http_port", "8222"]
  ports:
    - "11024:4222"
    - "11025:8222"
```

### Apicurio Registry
```yaml
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
```

### Volumes
```yaml
volumes:
  postgres-data:
```

**IMPORTANTE:** Los puertos internos del contenedor usan los puertos por defecto de cada servicio (5432, 2181, 9092, 5672, 4222, 8080). Los puertos del host usan el rango 11xxx. Los servicios dentro de la red Docker se comunican entre sí usando los puertos internos por defecto.

## Criterios de aceptación

- [ ] El fichero `docker-compose.yml` existe en la raíz del proyecto
- [ ] Todos los servicios tienen `profiles: ["infra"]`
- [ ] PostgreSQL tiene healthcheck
- [ ] Kafka depende de ZooKeeper
- [ ] Apicurio depende de PostgreSQL con condition: service_healthy
- [ ] `docker compose config --profiles infra` valida sin errores

## Validación

```bash
docker compose config --profiles infra
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`. Si necesitas instalar algo con sudo, crea una GitHub Issue con `gh issue create --title "Instalar {paquete}" --body "Se necesita: {detalle}"` y marca esta subtarea como bloqueada.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados, INCLUSO si la validación falla. El código se corregirá en la siguiente iteración.

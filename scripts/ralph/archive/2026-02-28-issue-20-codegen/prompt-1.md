# Tarea: Migraciones SQL para los 4 servicios

## Issue: #23
## Subtarea: 1 de 1

## Objetivo

Crear scripts SQL de migración para cada servicio. Cada servicio tiene su propio schema en PostgreSQL y una tabla `message_log` para persistir mensajes.

## Ficheros a crear

- `service-springboot/src/main/resources/db/migration/V1__init.sql`
- `service-quarkus/src/main/resources/db/migration/V1__init.sql`
- `service-go/migrations/001_init.sql`
- `service-node/migrations/001_init.sql`

## Contexto

PostgreSQL corre en `localhost:11010` con usuario `serialplab` y base de datos `serialplab`. Cada servicio usa un schema propio.

### service-springboot/src/main/resources/db/migration/V1__init.sql

```sql
-- Flyway migration: schema springboot
CREATE SCHEMA IF NOT EXISTS springboot;

CREATE TABLE IF NOT EXISTS springboot.message_log (
    id BIGSERIAL PRIMARY KEY,
    message_id UUID NOT NULL,
    broker VARCHAR(20) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    payload_size_bytes INTEGER,
    serialization_time_us BIGINT,
    deserialization_time_us BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_log_broker ON springboot.message_log(broker);
CREATE INDEX idx_message_log_protocol ON springboot.message_log(protocol);
```

### service-quarkus/src/main/resources/db/migration/V1__init.sql

```sql
-- Flyway migration: schema quarkus
CREATE SCHEMA IF NOT EXISTS quarkus;

CREATE TABLE IF NOT EXISTS quarkus.message_log (
    id BIGSERIAL PRIMARY KEY,
    message_id UUID NOT NULL,
    broker VARCHAR(20) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    payload_size_bytes INTEGER,
    serialization_time_us BIGINT,
    deserialization_time_us BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_log_broker ON quarkus.message_log(broker);
CREATE INDEX idx_message_log_protocol ON quarkus.message_log(protocol);
```

### service-go/migrations/001_init.sql

```sql
-- Migration: schema goservice
CREATE SCHEMA IF NOT EXISTS goservice;

CREATE TABLE IF NOT EXISTS goservice.message_log (
    id BIGSERIAL PRIMARY KEY,
    message_id UUID NOT NULL,
    broker VARCHAR(20) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    payload_size_bytes INTEGER,
    serialization_time_us BIGINT,
    deserialization_time_us BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_log_broker ON goservice.message_log(broker);
CREATE INDEX idx_message_log_protocol ON goservice.message_log(protocol);
```

### service-node/migrations/001_init.sql

```sql
-- Migration: schema node
CREATE SCHEMA IF NOT EXISTS node;

CREATE TABLE IF NOT EXISTS node.message_log (
    id BIGSERIAL PRIMARY KEY,
    message_id UUID NOT NULL,
    broker VARCHAR(20) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    payload_size_bytes INTEGER,
    serialization_time_us BIGINT,
    deserialization_time_us BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_log_broker ON node.message_log(broker);
CREATE INDEX idx_message_log_protocol ON node.message_log(protocol);
```

## Validación

```bash
test -f service-springboot/src/main/resources/db/migration/V1__init.sql && test -f service-quarkus/src/main/resources/db/migration/V1__init.sql && test -f service-go/migrations/001_init.sql && test -f service-node/migrations/001_init.sql && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

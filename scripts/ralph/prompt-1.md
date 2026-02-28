# Tarea: Docker Compose overlay para Apicurio Registry

## Issue: #9
## Subtarea: 1 de 2

## Objetivo

Crear un fichero Docker Compose overlay que añade Apicurio Registry al perfil `infra`, y un script SQL para inicializar la base de datos del registry.

## Ficheros a crear

- `apicurio/docker-compose.apicurio.yaml`
- `apicurio/init-registry-db.sql`

## Contexto

Apicurio Registry usa PostgreSQL como storage backend. La instancia PostgreSQL del proyecto corre en el puerto 11010 (host) / 5432 (contenedor). El registry expone su API en el puerto 11011.

### apicurio/docker-compose.apicurio.yaml

```yaml
services:
  apicurio-registry:
    image: apicurio/apicurio-registry:2.6.2.Final
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      REGISTRY_STORAGE_KIND: sql
      REGISTRY_STORAGE_SQL_KIND: postgresql
      REGISTRY_DATASOURCE_URL: jdbc:postgresql://postgres:5432/registry
      REGISTRY_DATASOURCE_USERNAME: registry
      REGISTRY_DATASOURCE_PASSWORD: registry
      QUARKUS_HTTP_PORT: 11011
    ports:
      - "11011:11011"
    profiles:
      - infra
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11011/health/ready"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
```

### apicurio/init-registry-db.sql

```sql
-- Inicializa la base de datos para Apicurio Registry
-- Se ejecuta como parte del init de PostgreSQL

CREATE USER registry WITH PASSWORD 'registry';
CREATE DATABASE registry OWNER registry;
GRANT ALL PRIVILEGES ON DATABASE registry TO registry;
```

## Validación

```bash
test -f apicurio/docker-compose.apicurio.yaml && test -f apicurio/init-registry-db.sql && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.
- **CRÍTICO:** NO incluir `version:` en el docker-compose yaml.

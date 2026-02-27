# Apicurio Registry

## Descripción

Registro centralizado de schemas y APIs para serialplab. Almacena y gestiona las definiciones de schemas utilizadas por los servicios para serialización/deserialización de mensajes.

## Características

| Propiedad | Valor |
|---|---|
| Puerto | 11011 |
| Imagen Docker | `apicurio/apicurio-registry:2.6.2.Final` |
| Storage backend | PostgreSQL (producción) / In-memory (desarrollo) |
| API compatible | Confluent Schema Registry v7 |
| Perfil Docker Compose | `infra` |

## Configuración Docker Compose

```yaml
apicurio-registry:
  image: apicurio/apicurio-registry:2.6.2.Final
  depends_on:
    - postgres
  environment:
    REGISTRY_STORAGE_KIND: sql
    REGISTRY_STORAGE_SQL_KIND: postgresql
    REGISTRY_DATASOURCE_URL: jdbc:postgresql://postgres:11010/registry
    REGISTRY_DATASOURCE_USERNAME: registry
    REGISTRY_DATASOURCE_PASSWORD: registry
  ports:
    - "11011:11011"
```

## Schemas registrados

| Artifact ID | Tipo | Schema origen |
|---|---|---|
| `message-avro` | AVRO | `schemas/avro/message.avsc` |
| `message-protobuf` | PROTOBUF | `schemas/protobuf/message.proto` |
| `message-json` | JSON | `schemas/jsonschema/message.schema.json` |

## Endpoints principales

| Endpoint | Descripción |
|---|---|
| `GET /apis/registry/v3/groups/{group}/artifacts` | Listar artifacts |
| `POST /apis/registry/v3/groups/{group}/artifacts` | Registrar artifact |
| `GET /apis/registry/v3/groups/{group}/artifacts/{id}/versions/latest/content` | Obtener schema |
| `GET /ui` | Interfaz web |
| `GET /apis/ccompat/v7/subjects` | API compatible Confluent |

## Reglas de compatibilidad

| Regla | Configuración |
|---|---|
| Validity | `FULL` (schema debe ser válido) |
| Compatibility | `BACKWARD` (nuevas versiones compatibles con la anterior) |

## Integración con servicios

Los servicios obtienen schemas de Apicurio Registry en runtime a través de la API REST o la API compatible con Confluent Schema Registry.

| Stack | Cliente |
|---|---|
| Spring Boot | `apicurio-registry-serdes-avro-serde` |
| Quarkus | `quarkus-apicurio-registry-avro` |
| Go | HTTP client directo (API REST) |
| Node.js | `@kafkajs/confluent-schema-registry` |

## Doc técnica

Para documentación general sobre Apicurio Registry (conceptos, arquitectura, instalación), ver [doc apicurio-registry](../../doc/registros/apicurio-registry.md).

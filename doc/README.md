# Documentación técnica — serialplab

Referencia técnica de cada tecnología utilizada en el proyecto. Aquí se documenta **qué es** cada tecnología, sus conceptos clave, arquitectura y casos de uso generales.

> Para ver cómo se usa cada componente **dentro de serialplab**, consulta [`specs/`](../specs/).

## Contenido

### Lenguajes

| Tecnología | Doc |
|---|---|
| Java | [java.md](lenguajes/java.md) |
| Go | [go.md](lenguajes/go.md) |
| Node.js + TypeScript | [nodejs-typescript.md](lenguajes/nodejs-typescript.md) |

### Frameworks

| Tecnología | Doc |
|---|---|
| Spring Boot | [spring-boot.md](frameworks/spring-boot.md) |
| Quarkus | [quarkus.md](frameworks/quarkus.md) |
| Express / Fastify | [express-fastify.md](frameworks/express-fastify.md) |

### Serialización

| Tecnología | Doc |
|---|---|
| Protocol Buffers | [protobuf.md](serializacion/protobuf.md) |
| Apache Avro | [avro.md](serializacion/avro.md) |
| Apache Thrift | [thrift.md](serializacion/thrift.md) |
| MessagePack | [messagepack.md](serializacion/messagepack.md) |
| FlatBuffers | [flatbuffers.md](serializacion/flatbuffers.md) |
| CBOR | [cbor.md](serializacion/cbor.md) |
| JSON Schema | [json-schema.md](serializacion/json-schema.md) |

### Brokers de mensajería

| Tecnología | Doc |
|---|---|
| Apache Kafka | [kafka.md](brokers/kafka.md) |
| RabbitMQ | [rabbitmq.md](brokers/rabbitmq.md) |
| NATS | [nats.md](brokers/nats.md) |

### Bases de datos

| Tecnología | Doc |
|---|---|
| PostgreSQL | [postgresql.md](bases-de-datos/postgresql.md) |

### Registros

| Tecnología | Doc |
|---|---|
| Apicurio Registry | [apicurio-registry.md](registros/apicurio-registry.md) |

### Infraestructura

| Tecnología | Doc |
|---|---|
| Docker | [docker.md](infraestructura/docker.md) |
| ZooKeeper | [zookeeper.md](infraestructura/zookeeper.md) |

### Especificaciones

| Tecnología | Doc |
|---|---|
| AsyncAPI | [asyncapi.md](especificaciones/asyncapi.md) |

## Convención

Cada archivo sigue esta estructura:

1. **Qué es** — descripción, creador, licencia
2. **Conceptos clave** — terminología y mecanismos internos
3. **Arquitectura** — cómo funciona (con diagrama Mermaid si aplica)
4. **Instalación / Docker** — cómo ejecutarlo
5. **Uso en serialplab** — enlace a spec en `specs/`
6. **Referencias** — documentación oficial

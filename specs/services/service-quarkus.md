# service-quarkus

## Descripción

Servicio basado en **Java 21 + Quarkus**. Compilación nativa con GraalVM, bajo consumo de memoria y arranque rápido.

## Stack tecnológico

| Propiedad | Valor |
|---|---|
| Lenguaje | Java 21 |
| Framework | Quarkus |
| Puerto | 11002 |
| Build | Maven (Quarkus BOM) |
| Base de datos | PostgreSQL 16 (schema: `quarkus`) |

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Readiness/liveness probe |
| POST | `/publish/{target}/{protocol}/{broker}` | Publica mensaje al servicio destino con protocolo y broker indicados |
| GET | `/messages` | Lista mensajes recibidos |

## Protocolos soportados

| Protocolo | Librería principal | Spec |
|---|---|---|
| Protobuf | `com.google.protobuf:protobuf-java` | [protobuf.md](../protocols/protobuf.md) |
| Avro | `org.apache.avro:avro` | [avro.md](../protocols/avro.md) |
| Thrift | `org.apache.thrift:libthrift` | [thrift.md](../protocols/thrift.md) |
| MessagePack | `org.msgpack:msgpack-core` | [messagepack.md](../protocols/messagepack.md) |
| FlatBuffers | `com.google.flatbuffers:flatbuffers-java` | [flatbuffers.md](../protocols/flatbuffers.md) |
| CBOR | `com.fasterxml.jackson.dataformat:jackson-dataformat-cbor` | [cbor.md](../protocols/cbor.md) |
| JSON Schema | `com.networknt:json-schema-validator` | [json-schema.md](../protocols/json-schema.md) |

## Brokers soportados

| Broker | Librería principal | Spec |
|---|---|---|
| Kafka | `io.quarkus:quarkus-messaging-kafka` | [kafka.md](../brokers/kafka.md) |
| RabbitMQ | `io.quarkus:quarkus-messaging-rabbitmq` | [rabbitmq.md](../brokers/rabbitmq.md) |
| NATS | `io.nats:jnats` | [nats.md](../brokers/nats.md) |

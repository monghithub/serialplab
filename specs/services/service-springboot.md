# service-springboot

## Descripción

Servicio basado en **Java 21 + Spring Boot 3**. Ecosistema maduro con amplio soporte de serialización y conectores de mensajería.

## Stack tecnológico

| Propiedad | Valor |
|---|---|
| Lenguaje | Java 21 |
| Framework | Spring Boot 3 |
| Puerto | 11001 |
| Build | Maven / Gradle |
| Base de datos | PostgreSQL 16 (schema: `springboot`) |

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
| Kafka | `org.springframework.kafka:spring-kafka` | [kafka.md](../brokers/kafka.md) |
| RabbitMQ | `org.springframework.amqp:spring-rabbit` | [rabbitmq.md](../brokers/rabbitmq.md) |
| NATS | `io.nats:jnats` | [nats.md](../brokers/nats.md) |

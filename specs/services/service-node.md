# service-node

## Descripción

Servicio basado en **Node.js 22 + Express/Fastify**. Prototipado rápido y amplio ecosistema npm.

## Stack tecnológico

| Propiedad | Valor |
|---|---|
| Lenguaje | Node.js 22 (TypeScript) |
| Framework | Express / Fastify |
| Puerto | 8084 |
| Build | `npm run build` |
| Base de datos | PostgreSQL 16 (schema: `node`) |

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Readiness/liveness probe |
| POST | `/publish/:protocol/:broker` | Publica mensaje con protocolo y broker indicados |
| GET | `/messages` | Lista mensajes recibidos |

## Protocolos soportados

| Protocolo | Librería principal | Spec |
|---|---|---|
| Protobuf | `protobufjs` | [protobuf.md](../protocols/protobuf.md) |
| Avro | `avsc` | [avro.md](../protocols/avro.md) |
| Thrift | `thrift` | [thrift.md](../protocols/thrift.md) |
| MessagePack | `@msgpack/msgpack` | [messagepack.md](../protocols/messagepack.md) |
| FlatBuffers | `flatbuffers` | [flatbuffers.md](../protocols/flatbuffers.md) |
| CBOR | `cbor-x` | [cbor.md](../protocols/cbor.md) |
| JSON Schema | `ajv` | [json-schema.md](../protocols/json-schema.md) |

## Brokers soportados

| Broker | Librería principal | Spec |
|---|---|---|
| Kafka | `kafkajs` | [kafka.md](../brokers/kafka.md) |
| RabbitMQ | `amqplib` | [rabbitmq.md](../brokers/rabbitmq.md) |
| NATS | `nats` | [nats.md](../brokers/nats.md) |

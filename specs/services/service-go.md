# service-go

## Descripción

Servicio basado en **Go 1.22+**. Alto rendimiento, binarios estáticos y bajo consumo de recursos.

## Stack tecnológico

| Propiedad | Valor |
|---|---|
| Lenguaje | Go 1.22+ |
| Framework | net/http (stdlib) / Chi |
| Puerto | 11003 |
| Build | `go build` |
| Base de datos | PostgreSQL 16 (schema: `goservice`) |

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Readiness/liveness probe |
| POST | `/publish/{target}/{protocol}/{broker}` | Publica mensaje al servicio destino con protocolo y broker indicados |
| GET | `/messages` | Lista mensajes recibidos |

## Protocolos soportados

| Protocolo | Librería principal | Spec |
|---|---|---|
| Protobuf | `google.golang.org/protobuf` | [protobuf.md](../protocols/protobuf.md) |
| Avro | `github.com/linkedin/goavro/v2` | [avro.md](../protocols/avro.md) |
| Thrift | `github.com/apache/thrift/lib/go/thrift` | [thrift.md](../protocols/thrift.md) |
| MessagePack | `github.com/vmihailenco/msgpack/v5` | [messagepack.md](../protocols/messagepack.md) |
| FlatBuffers | `github.com/google/flatbuffers/go` | [flatbuffers.md](../protocols/flatbuffers.md) |
| CBOR | `github.com/fxamacker/cbor/v2` | [cbor.md](../protocols/cbor.md) |
| JSON Schema | `github.com/santhosh-tekuri/jsonschema/v5` | [json-schema.md](../protocols/json-schema.md) |

## Brokers soportados

| Broker | Librería principal | Spec |
|---|---|---|
| Kafka | `github.com/segmentio/kafka-go` | [kafka.md](../brokers/kafka.md) |
| RabbitMQ | `github.com/rabbitmq/amqp091-go` | [rabbitmq.md](../brokers/rabbitmq.md) |
| NATS | `github.com/nats-io/nats.go` | [nats.md](../brokers/nats.md) |

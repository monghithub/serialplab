# Protocolos de serialización — serialplab

Formatos utilizados para serializar y deserializar los mensajes intercambiados entre servicios.

## Índice

| # | Protocolo | Formato | Schema obligatorio | Spec |
|---|---|---|---|---|
| 1 | Protocol Buffers | Binario | Sí (`.proto`) | [protobuf.md](protobuf.md) |
| 2 | Apache Avro | Binario | Sí (JSON schema) | [avro.md](avro.md) |
| 3 | Apache Thrift | Binario | Sí (`.thrift`) | [thrift.md](thrift.md) |
| 4 | MessagePack | Binario | No | [messagepack.md](messagepack.md) |
| 5 | FlatBuffers | Binario | Sí (`.fbs`) | [flatbuffers.md](flatbuffers.md) |
| 6 | CBOR | Binario | No | [cbor.md](cbor.md) |
| 7 | JSON Schema | Texto (JSON) | Sí (JSON Schema) | [json-schema.md](json-schema.md) |

## Schemas compartidos

Los archivos de definición se centralizan en `schemas/` en la raíz del proyecto. Cada servicio importa o genera código a partir de estas definiciones.

```
schemas/
├── protobuf/       → message.proto
├── avro/           → message.avsc
├── thrift/         → message.thrift
├── flatbuffers/    → message.fbs
└── jsonschema/     → message.schema.json
```

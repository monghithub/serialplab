# Tarea: Actualizar dependencias Go y Node.js

## Issue: #20
## Subtarea: 2 de 2

## Objetivo

Actualizar `go.mod` y `package.json` con las dependencias de serialización que faltan.

## Ficheros a modificar

- `service-go/go.mod` (contenido COMPLETO abajo)
- `service-node/package.json` (contenido COMPLETO abajo)

## Contexto

Los servicios Go y Node les faltan librerías de serialización para protobuf, avro, thrift y flatbuffers.

### service-go/go.mod

```
module serialplab/service-go

go 1.22

require (
	github.com/go-chi/chi/v5 v5.2.1
	github.com/lib/pq v1.10.9
	github.com/segmentio/kafka-go v0.4.47
	github.com/rabbitmq/amqp091-go v1.10.0
	github.com/nats-io/nats.go v1.38.0
	github.com/vmihailenco/msgpack/v5 v5.4.1
	github.com/fxamacker/cbor/v2 v2.7.0
	google.golang.org/protobuf v1.36.4
	github.com/linkedin/goavro/v2 v2.13.0
	github.com/apache/thrift v0.21.0
	github.com/google/flatbuffers v24.12.23+incompatible
	github.com/santhosh-tekuri/jsonschema/v6 v6.0.1
)
```

### service-node/package.json

```json
{
  "name": "service-node",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts",
    "generate:proto": "pbjs -t static-module -w es6 -o src/generated/message.js ../schemas/protobuf/message.proto && pbts -o src/generated/message.d.ts src/generated/message.js"
  },
  "dependencies": {
    "express": "^4.21.2",
    "pg": "^8.13.1",
    "kafkajs": "^2.2.4",
    "amqplib": "^0.10.5",
    "nats": "^2.29.1",
    "@msgpack/msgpack": "^3.0.0-beta2",
    "cbor-x": "^1.6.0",
    "protobufjs": "^7.4.0",
    "avsc": "^5.7.7",
    "thrift": "^0.21.0",
    "flatbuffers": "^24.12.23",
    "ajv": "^8.17.1",
    "ajv-formats": "^3.0.1"
  },
  "devDependencies": {
    "typescript": "^5.7.3",
    "@types/express": "^5.0.0",
    "@types/pg": "^8.11.11",
    "@types/amqplib": "^0.10.6",
    "ts-node": "^10.9.2"
  }
}
```

## Validación

```bash
grep -q "google.golang.org/protobuf" service-go/go.mod && grep -q "goavro" service-go/go.mod && grep -q "protobufjs" service-node/package.json && grep -q "avsc" service-node/package.json && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

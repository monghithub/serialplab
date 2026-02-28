# Tarea: Contrato AsyncAPI 3.0 para Kafka

## Issue: #8
## Subtarea: 1 de 2

## Objetivo

Crear el contrato AsyncAPI 3.0 para Apache Kafka.

## Ficheros a crear

- `asyncapi/kafka.asyncapi.yaml`

## Contexto

AsyncAPI 3.0 usa `channels`, `operations`, `messages` y `components`. El topic sigue el patrón `serialplab.{target}.{protocol}`.

### kafka.asyncapi.yaml

```yaml
asyncapi: 3.0.0
info:
  title: serialplab - Kafka
  version: 0.0.1
  description: Contratos de mensajería Kafka para serialplab

servers:
  kafka:
    host: localhost:11021
    protocol: kafka
    description: Apache Kafka broker

channels:
  serialplabMessages:
    address: "serialplab.{target}.{protocol}"
    messages:
      userMessage:
        $ref: "#/components/messages/UserMessage"
    parameters:
      target:
        description: Servicio destino (service-springboot, service-quarkus, service-go, service-node)
      protocol:
        description: Protocolo de serialización (protobuf, avro, thrift, messagepack, flatbuffers, cbor, json-schema)
    bindings:
      kafka:
        partitions: 1
        replicas: 1

operations:
  publishMessage:
    action: send
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Publica un mensaje User serializado al topic Kafka
    messages:
      - $ref: "#/channels/serialplabMessages/messages/userMessage"

  consumeMessage:
    action: receive
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Consume un mensaje User del topic Kafka
    bindings:
      kafka:
        groupId: "{service}-group"
    messages:
      - $ref: "#/channels/serialplabMessages/messages/userMessage"

components:
  messages:
    UserMessage:
      name: UserMessage
      title: User message
      contentType: application/octet-stream
      payload:
        $ref: "#/components/schemas/User"

  schemas:
    User:
      type: object
      required:
        - id
        - name
        - email
        - timestamp
      properties:
        id:
          type: string
          format: uuid
          description: UUID del usuario
        name:
          type: string
          description: Nombre del usuario
        email:
          type: string
          format: email
          description: Email del usuario
        timestamp:
          type: integer
          format: int64
          description: Epoch milliseconds
```

## Validación

```bash
test -f asyncapi/kafka.asyncapi.yaml && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

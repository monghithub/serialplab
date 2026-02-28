# Tarea: Contratos AsyncAPI 3.0 para RabbitMQ y NATS

## Issue: #8
## Subtarea: 2 de 2

## Objetivo

Crear los contratos AsyncAPI 3.0 para RabbitMQ y NATS.

## Ficheros a crear

- `asyncapi/rabbitmq.asyncapi.yaml`
- `asyncapi/nats.asyncapi.yaml`

## Contexto

### rabbitmq.asyncapi.yaml

```yaml
asyncapi: 3.0.0
info:
  title: serialplab - RabbitMQ
  version: 0.0.1
  description: Contratos de mensajería RabbitMQ para serialplab

servers:
  rabbitmq:
    host: localhost:11022
    protocol: amqp
    description: RabbitMQ broker

channels:
  serialplabMessages:
    address: "serialplab.{target}.{protocol}"
    messages:
      userMessage:
        $ref: "#/components/messages/UserMessage"
    parameters:
      target:
        description: Servicio destino
      protocol:
        description: Protocolo de serialización
    bindings:
      amqp:
        is: queue
        queue:
          durable: true
          autoDelete: false

operations:
  publishMessage:
    action: send
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Publica un mensaje User a la queue RabbitMQ
    messages:
      - $ref: "#/channels/serialplabMessages/messages/userMessage"

  consumeMessage:
    action: receive
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Consume un mensaje User de la queue RabbitMQ
    bindings:
      amqp:
        ack: true
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
        name:
          type: string
        email:
          type: string
          format: email
        timestamp:
          type: integer
          format: int64
```

### nats.asyncapi.yaml

```yaml
asyncapi: 3.0.0
info:
  title: serialplab - NATS
  version: 0.0.1
  description: Contratos de mensajería NATS para serialplab

servers:
  nats:
    host: localhost:11024
    protocol: nats
    description: NATS server con JetStream

channels:
  serialplabMessages:
    address: "serialplab.{target}.{protocol}"
    messages:
      userMessage:
        $ref: "#/components/messages/UserMessage"
    parameters:
      target:
        description: Servicio destino
      protocol:
        description: Protocolo de serialización

operations:
  publishMessage:
    action: send
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Publica un mensaje User al subject NATS
    messages:
      - $ref: "#/channels/serialplabMessages/messages/userMessage"

  consumeMessage:
    action: receive
    channel:
      $ref: "#/channels/serialplabMessages"
    summary: Consume un mensaje User del subject NATS
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
        name:
          type: string
        email:
          type: string
          format: email
        timestamp:
          type: integer
          format: int64
```

## Validación

```bash
test -f asyncapi/rabbitmq.asyncapi.yaml && test -f asyncapi/nats.asyncapi.yaml && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

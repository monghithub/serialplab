# RabbitMQ

## Descripción

Broker de mensajería basado en AMQP 0-9-1. Routing flexible mediante exchanges y bindings. Incluye UI de gestión.

## Características

| Propiedad | Valor |
|---|---|
| Protocolo nativo | AMQP 0-9-1 |
| Puertos | 11022 (AMQP), 11023 (Management UI) |
| Imagen Docker | `rabbitmq:management` |
| Dependencias | Ninguna |
| Paradigma | Cola de mensajes, routing por exchange |

## Configuración Docker Compose

```yaml
rabbitmq:
  image: rabbitmq:management
  environment:
    RABBITMQ_DEFAULT_USER: guest
    RABBITMQ_DEFAULT_PASS: guest
  ports:
    - "11022:11022"
    - "11023:11023"
```

## Colas y exchanges utilizados

| Exchange | Tipo | Cola | Descripción |
|---|---|---|---|
| `serialplab.direct` | direct | `serialplab.messages` | Mensajes punto a punto |
| `serialplab.fanout` | fanout | (auto-generadas) | Broadcast a todos los consumidores |

## Librerías cliente por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `spring-rabbit` | Integración con Spring AMQP |
| Quarkus | `quarkus-messaging-rabbitmq` | SmallRye Reactive Messaging |
| Go | `github.com/rabbitmq/amqp091-go` | Cliente AMQP oficial |
| Node.js | `amqplib` | Cliente AMQP más usado en npm |

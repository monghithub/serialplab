# Brokers de mensajería — serialplab

Sistemas de mensajería utilizados para la comunicación asíncrona entre servicios.

## Índice

| # | Broker | Protocolo nativo | Puerto(s) | Spec |
|---|---|---|---|---|
| 1 | Apache Kafka | TCP binario | 9092 | [kafka.md](kafka.md) |
| 2 | RabbitMQ | AMQP 0-9-1 | 5672, 15672 | [rabbitmq.md](rabbitmq.md) |
| 3 | NATS | TCP texto/binario | 4222, 8222 | [nats.md](nats.md) |

## Criterios de selección

Estos 3 brokers cubren los paradigmas principales:

- **Kafka**: Log distribuido, alto throughput, retención de mensajes.
- **RabbitMQ**: Cola de mensajes tradicional, routing flexible, AMQP estándar.
- **NATS**: Mensajería ligera, baja latencia, pub/sub simple.

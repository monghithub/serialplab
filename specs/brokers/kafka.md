# Apache Kafka

## Descripción

Plataforma de streaming distribuida basada en un log de eventos. Alto throughput, retención configurable de mensajes y garantías de ordenación por partición.

## Características

| Propiedad | Valor |
|---|---|
| Protocolo nativo | TCP binario |
| Puerto | 9092 |
| Imagen Docker | `confluentinc/cp-kafka` |
| Dependencias | ZooKeeper o KRaft (modo standalone) |
| Paradigma | Log distribuido, pub/sub con consumer groups |

## Configuración Docker Compose

```yaml
zookeeper:
  image: confluentinc/cp-zookeeper:7.6.0
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181
  ports:
    - "2181:2181"

kafka:
  image: confluentinc/cp-kafka:7.6.0
  depends_on:
    - zookeeper
  environment:
    KAFKA_BROKER_ID: 1
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
  ports:
    - "9092:9092"
```

## Tópicos utilizados

| Tópico | Descripción |
|---|---|
| `serialplab.messages` | Tópico principal para intercambio de mensajes |
| `serialplab.benchmarks` | Resultados de benchmarks |

## Librerías cliente por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `spring-kafka` | Integración con Spring Messaging |
| Quarkus | `quarkus-messaging-kafka` | SmallRye Reactive Messaging |
| Go | `github.com/segmentio/kafka-go` | Alternativa: `confluent-kafka-go` |
| Node.js | `kafkajs` | Cliente puro JS, sin dependencias nativas |

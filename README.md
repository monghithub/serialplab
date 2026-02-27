# serialplab

Proof of Concept (PoC) que evalúa la intercomunicación entre servicios heterogéneos utilizando múltiples formatos de serialización y sistemas de mensajería.

**4 servicios** × **7 protocolos** × **3 brokers** = **84 combinaciones**

## Arquitectura de alto nivel

```mermaid
graph TB
    subgraph Servicios
        SB["service-springboot<br/>Java 21 + Spring Boot 3<br/>:8081"]
        QK["service-quarkus<br/>Java 21 + Quarkus<br/>:8082"]
        GO["service-go<br/>Go 1.22+<br/>:8083"]
        ND["service-node<br/>Node.js 22<br/>:8084"]
    end

    subgraph Serialización["Capa de serialización (x7)"]
        PROTO["Protobuf"]
        AVRO["Avro"]
        THRIFT["Thrift"]
        MSGPACK["MessagePack"]
        FLAT["FlatBuffers"]
        CBOR["CBOR"]
        JSON["JSON Schema"]
    end

    subgraph Brokers["Brokers de mensajería"]
        KFK["Apache Kafka<br/>:9092"]
        RMQ["RabbitMQ<br/>:5672"]
        NATS["NATS<br/>:4222"]
    end

    PG[("PostgreSQL 16<br/>:5432")]

    SB & QK & GO & ND --> Serialización
    Serialización --> KFK & RMQ & NATS
    SB & QK & GO & ND --> PG
```

## Flujo de mensajes

```mermaid
sequenceDiagram
    participant P as Servicio Publisher
    participant S as Capa Serialización
    participant B as Broker
    participant D as Capa Deserialización
    participant C as Servicio Consumer
    participant DB as PostgreSQL

    P->>S: Objeto del dominio
    S->>S: Serializar (protocolo elegido)
    S->>B: bytes[]
    B->>D: bytes[]
    D->>D: Deserializar (protocolo elegido)
    D->>C: Objeto del dominio
    C->>DB: Persistir mensaje + métricas
```

## Infraestructura Docker

```mermaid
graph LR
    subgraph infra["Perfil: infra"]
        ZK["ZooKeeper<br/>:2181"]
        KFK["Kafka<br/>:9092"]
        RMQ["RabbitMQ<br/>:5672 / :15672"]
        NATS["NATS<br/>:4222 / :8222"]
        PG[("PostgreSQL<br/>:5432")]
        ZK --> KFK
    end

    subgraph app["Perfil: app"]
        SB["springboot :8081"]
        QK["quarkus :8082"]
        GO["go :8083"]
        ND["node :8084"]
    end

    SB & QK & GO & ND --> KFK & RMQ & NATS & PG
```

## Servicios

| Servicio | Stack | Puerto | Spec |
|---|---|---|---|
| `service-springboot` | Java 21 + Spring Boot 3 | 8081 | [spec](specs/services/service-springboot.md) |
| `service-quarkus` | Java 21 + Quarkus | 8082 | [spec](specs/services/service-quarkus.md) |
| `service-go` | Go 1.22+ | 8083 | [spec](specs/services/service-go.md) |
| `service-node` | Node.js 22 + Express/Fastify | 8084 | [spec](specs/services/service-node.md) |

## Protocolos de serialización

| Protocolo | Formato | Schema | Spec |
|---|---|---|---|
| Protocol Buffers | Binario | `.proto` | [spec](specs/protocols/protobuf.md) |
| Apache Avro | Binario | `.avsc` | [spec](specs/protocols/avro.md) |
| Apache Thrift | Binario | `.thrift` | [spec](specs/protocols/thrift.md) |
| MessagePack | Binario | No | [spec](specs/protocols/messagepack.md) |
| FlatBuffers | Binario | `.fbs` | [spec](specs/protocols/flatbuffers.md) |
| CBOR | Binario | No | [spec](specs/protocols/cbor.md) |
| JSON Schema | Texto | JSON Schema | [spec](specs/protocols/json-schema.md) |

## Brokers de mensajería

| Broker | Protocolo nativo | Puertos | Spec |
|---|---|---|---|
| Apache Kafka | TCP binario | 9092 | [spec](specs/brokers/kafka.md) |
| RabbitMQ | AMQP 0-9-1 | 5672, 15672 | [spec](specs/brokers/rabbitmq.md) |
| NATS | TCP texto/binario | 4222, 8222 | [spec](specs/brokers/nats.md) |

## Matriz de compatibilidad

```mermaid
block-beta
    columns 5
    space:5
    block:header:5
        columns 5
        h0["Protocolo"] h1["springboot"] h2["quarkus"] h3["go"] h4["node"]
    end
    block:row1:5
        columns 5
        r1c0["Protobuf"] r1c1["✅"] r1c2["✅"] r1c3["✅"] r1c4["✅"]
    end
    block:row2:5
        columns 5
        r2c0["Avro"] r2c1["✅"] r2c2["✅"] r2c3["✅"] r2c4["✅"]
    end
    block:row3:5
        columns 5
        r3c0["Thrift"] r3c1["✅"] r3c2["✅"] r3c3["✅"] r3c4["✅"]
    end
    block:row4:5
        columns 5
        r4c0["MessagePack"] r4c1["✅"] r4c2["✅"] r4c3["✅"] r4c4["✅"]
    end
    block:row5:5
        columns 5
        r5c0["FlatBuffers"] r5c1["✅"] r5c2["✅"] r5c3["✅"] r5c4["✅"]
    end
    block:row6:5
        columns 5
        r6c0["CBOR"] r6c1["✅"] r6c2["✅"] r6c3["✅"] r6c4["✅"]
    end
    block:row7:5
        columns 5
        r7c0["JSON Schema"] r7c1["✅"] r7c2["✅"] r7c3["✅"] r7c4["✅"]
    end
```

Todos los servicios soportan los 3 brokers (Kafka, RabbitMQ, NATS) → **4 × 7 × 3 = 84 combinaciones**.

## Estructura del proyecto

```
serialplab/
├── README.md                    ← este archivo
├── ARCHITECTURE.md              ← arquitectura detallada
├── specs/
│   ├── services/                ← specs por servicio
│   ├── protocols/               ← specs por protocolo
│   └── brokers/                 ← specs por broker
├── schemas/                     ← definiciones de schemas compartidos
├── asyncapi/                    ← contratos AsyncAPI 3.0
├── service-springboot/
├── service-quarkus/
├── service-go/
├── service-node/
└── docker-compose.yml
```

## Quick start

```bash
# Levantar infraestructura
docker compose --profile infra up -d

# Levantar todos los servicios
docker compose --profile infra --profile app up -d

# Ver logs de un servicio
docker compose logs -f service-go

# Parar todo
docker compose down
```

## Documentación

- [ARCHITECTURE.md](ARCHITECTURE.md) — Arquitectura completa del proyecto
- [specs/](specs/) — Specs modulares de servicios, protocolos y brokers

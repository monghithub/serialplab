# serialplab

Proof of Concept (PoC) que evalúa la intercomunicación entre servicios heterogéneos utilizando múltiples formatos de serialización y sistemas de mensajería.

**4 servicios** × **7 protocolos** × **3 brokers** = **84 combinaciones**

## Arquitectura de alto nivel

```mermaid
graph TB
    FE["frontend-angular<br/>Angular 19<br/>:11000"]

    subgraph Servicios
        SB["service-springboot<br/>Java 21 + Spring Boot 3<br/>:11001"]
        QK["service-quarkus<br/>Java 21 + Quarkus<br/>:11002"]
        GO["service-go<br/>Go 1.22+<br/>:11003"]
        ND["service-node<br/>Node.js 22<br/>:11004"]
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
        KFK["Apache Kafka<br/>:11021"]
        RMQ["RabbitMQ<br/>:11022"]
        NATS["NATS<br/>:11024"]
    end

    PG[("PostgreSQL 16<br/>:11010")]

    FE -->|HTTP| SB & QK & GO & ND
    SB & QK & GO & ND --> Serialización
    Serialización --> KFK & RMQ & NATS
    SB & QK & GO & ND --> PG
```

## Flujo de mensajes

```mermaid
sequenceDiagram
    participant FE as Frontend Angular
    participant P as Servicio Publisher
    participant S as Capa Serialización
    participant B as Broker
    participant D as Capa Deserialización
    participant C as Servicio Consumer
    participant DB as PostgreSQL

    FE->>P: POST /publish/{target}/{protocol}/{broker}
    P->>S: Objeto del dominio
    S->>S: Serializar (protocolo elegido)
    S->>B: bytes[]
    B->>D: bytes[]
    D->>D: Deserializar (protocolo elegido)
    D->>C: Objeto del dominio
    C->>DB: Persistir mensaje + métricas
    P-->>FE: Respuesta HTTP
```

## Infraestructura Docker

```mermaid
graph LR
    subgraph infra["Perfil: infra"]
        ZK["ZooKeeper<br/>:11020"]
        KFK["Kafka<br/>:11021"]
        RMQ["RabbitMQ<br/>:11022 / :11023"]
        NATS["NATS<br/>:11024 / :11025"]
        PG[("PostgreSQL<br/>:11010")]
        AR["Apicurio Registry<br/>:11011"]
        ZK --> KFK
        PG --> AR
    end

    subgraph app["Perfil: app"]
        FE["angular :11000"]
        SB["springboot :11001"]
        QK["quarkus :11002"]
        GO["go :11003"]
        ND["node :11004"]
    end

    FE -->|HTTP| SB & QK & GO & ND
    SB & QK & GO & ND --> KFK & RMQ & NATS & PG & AR
```

## Frontend

| Aplicación | Stack | Puerto | Spec |
|---|---|---|---|
| `frontend-angular` | Angular 19 + TypeScript | 11000 | [spec](specs/frontend/frontend-angular.md) |

## Servicios

| Servicio | Stack | Puerto | Spec |
|---|---|---|---|
| `service-springboot` | Java 21 + Spring Boot 3 | 11001 | [spec](specs/services/service-springboot.md) |
| `service-quarkus` | Java 21 + Quarkus | 11002 | [spec](specs/services/service-quarkus.md) |
| `service-go` | Go 1.22+ | 11003 | [spec](specs/services/service-go.md) |
| `service-node` | Node.js 22 + Express/Fastify | 11004 | [spec](specs/services/service-node.md) |

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
| Apache Kafka | TCP binario | 11021 | [spec](specs/brokers/kafka.md) |
| RabbitMQ | AMQP 0-9-1 | 11022, 11023 | [spec](specs/brokers/rabbitmq.md) |
| NATS | TCP texto/binario | 11024, 11025 | [spec](specs/brokers/nats.md) |

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
├── doc/                         ← documentación técnica de referencia
│   ├── lenguajes/               ← Java, Go, Node.js/TypeScript
│   ├── frameworks/              ← Spring Boot, Quarkus, Express/Fastify
│   ├── frontend/                ← Angular
│   ├── serializacion/           ← Protobuf, Avro, Thrift, MessagePack, ...
│   ├── brokers/                 ← Kafka, RabbitMQ, NATS
│   ├── bases-de-datos/          ← PostgreSQL
│   ├── registros/               ← Apicurio Registry
│   ├── infraestructura/         ← Docker, ZooKeeper
│   └── especificaciones/        ← AsyncAPI
├── specs/                       ← specs de uso en serialplab
│   ├── services/                ← specs por servicio
│   ├── frontend/                ← specs del frontend
│   ├── protocols/               ← specs por protocolo
│   ├── brokers/                 ← specs por broker
│   └── registros/               ← specs de registros de schemas
├── schemas/                     ← definiciones de schemas compartidos
├── asyncapi/                    ← contratos AsyncAPI 3.0
├── frontend-angular/
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
- [doc/](doc/) — Documentación técnica de referencia (qué es cada tecnología)
- [specs/](specs/) — Specs modulares de uso en serialplab (cómo se usa cada componente)

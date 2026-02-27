# Arquitectura — serialplab

## 1. Visión general

**serialplab** es una Proof of Concept (PoC) que evalúa la intercomunicación entre servicios heterogéneos utilizando múltiples formatos de serialización y sistemas de mensajería.

### Objetivo

Comparar el rendimiento, la interoperabilidad y la complejidad de integración de **7 protocolos de serialización** sobre **3 brokers de mensajería**, implementados en **4 stacks tecnológicos** distintos.

### Alcance

- Comunicación asíncrona entre servicios mediante brokers.
- Serialización y deserialización de mensajes en cada combinación protocolo × servicio.
- Métricas de tamaño de payload, latencia de (de)serialización y throughput.
- Definición de contratos async con AsyncAPI.

### Motivación

En arquitecturas de microservicios reales conviven múltiples lenguajes y brokers. Esta PoC proporciona datos empíricos para decidir qué combinaciones son viables y cuáles ofrecen mejor rendimiento o menor fricción de desarrollo.

### Specs detalladas

La carpeta [`specs/`](specs/) contiene documentación modular de cada componente:

- [`specs/services/`](specs/services/) — Specs de cada servicio (stack, librerías, endpoints).
- [`specs/protocols/`](specs/protocols/) — Specs de cada protocolo de serialización.
- [`specs/brokers/`](specs/brokers/) — Specs de cada broker de mensajería.

---

## 2. Servicios

Todos los servicios se ejecutan en contenedores Docker y exponen un puerto HTTP para health checks y endpoints de prueba.

| Servicio | Stack | Puerto base | Notas |
|---|---|---|---|
| `service-springboot` | Java 21 + Spring Boot 3 | 8081 | Ecosistema maduro, amplio soporte de serialización |
| `service-quarkus` | Java 21 + Quarkus | 8082 | Compilación nativa (GraalVM), bajo consumo de memoria |
| `service-go` | Go 1.22+ | 8083 | Alto rendimiento, binarios estáticos |
| `service-node` | Node.js 22 + Express/Fastify | 8084 | Prototipado rápido, ecosistema npm |

Cada servicio:

- Publica y consume mensajes en todos los brokers configurados.
- Soporta los 7 protocolos de serialización.
- Expone `/health` para readiness/liveness probes.
- Se conecta a PostgreSQL con su propio schema.

---

## 3. Protocolos de serialización

| # | Protocolo | Formato | Schema obligatorio | Notas |
|---|---|---|---|---|
| 1 | **Protocol Buffers (Protobuf)** | Binario | Sí (`.proto`) | Estándar de facto en gRPC |
| 2 | **Apache Avro** | Binario | Sí (JSON schema) | Schema evolution nativa, uso común con Kafka |
| 3 | **Apache Thrift** | Binario | Sí (`.thrift`) | IDL propia, genera código multi-lenguaje |
| 4 | **MessagePack** | Binario | No | JSON binario, schema-less |
| 5 | **FlatBuffers** | Binario | Sí (`.fbs`) | Zero-copy, acceso sin deserialización completa |
| 6 | **CBOR** | Binario | No | Estándar IETF (RFC 8949), compacto |
| 7 | **JSON Schema** | Texto (JSON) | Sí (JSON Schema) | Baseline de comparación, legible por humanos |

### Schemas compartidos

Los archivos de definición de schemas (`.proto`, `.avsc`, `.thrift`, `.fbs`, JSON Schema) se centralizan en el directorio `schemas/` en la raíz del proyecto. Cada servicio importa o genera código a partir de estas definiciones.

```
schemas/
├── protobuf/
│   └── message.proto
├── avro/
│   └── message.avsc
├── thrift/
│   └── message.thrift
├── flatbuffers/
│   └── message.fbs
└── jsonschema/
    └── message.schema.json
```

---

## 4. Sistemas de mensajería

| # | Broker | Protocolo nativo | Puerto(s) | Imagen Docker |
|---|---|---|---|---|
| 1 | **Apache Kafka** | TCP binario | 9092 | `confluentinc/cp-kafka` |
| 2 | **RabbitMQ** | AMQP 0-9-1 | 5672, 15672 (mgmt) | `rabbitmq:management` |
| 3 | **NATS** | TCP texto/binario | 4222, 8222 (monitor) | `nats:latest` |

Estos 3 brokers cubren los paradigmas principales:

- **Kafka**: Log distribuido, alto throughput, retención de mensajes.
- **RabbitMQ**: Cola de mensajes tradicional, routing flexible, AMQP estándar.
- **NATS**: Mensajería ligera, baja latencia, pub/sub simple.

### Dependencias de infraestructura

- **Kafka** requiere ZooKeeper (o KRaft en modo standalone).

---

## 5. Base de datos

| Componente | Detalle |
|---|---|
| Motor | PostgreSQL 16 |
| Puerto | 5432 |
| Imagen Docker | `postgres:16` |
| Aislamiento | Un schema por servicio (`springboot`, `quarkus`, `goservice`, `node`) |

Cada servicio gestiona sus propias migraciones. La base de datos se usa para persistir mensajes recibidos y resultados de benchmarks.

---

## 6. AsyncAPI

Se utiliza [AsyncAPI 3.0](https://www.asyncapi.com/) para documentar los contratos de comunicación asíncrona.

### Estructura

```
asyncapi/
├── kafka.asyncapi.yaml
├── rabbitmq.asyncapi.yaml
└── nats.asyncapi.yaml
```

Cada archivo define:

- **Canales**: topic/queue por broker (ej. `serialplab.messages` en Kafka).
- **Mensajes**: estructura del payload con referencia al schema de serialización.
- **Operaciones**: publish/subscribe por servicio.
- **Bindings**: configuración específica del broker (particiones, durabilidad, QoS).

---

## 7. Matriz de compatibilidad

Todas las combinaciones servicio × protocolo × broker están soportadas. La siguiente matriz resume el estado objetivo:

### Servicio × Protocolo

| Protocolo | springboot | quarkus | go | node |
|---|---|---|---|---|
| Protobuf | Si | Si | Si | Si |
| Avro | Si | Si | Si | Si |
| Thrift | Si | Si | Si | Si |
| MessagePack | Si | Si | Si | Si |
| FlatBuffers | Si | Si | Si | Si |
| CBOR | Si | Si | Si | Si |
| JSON Schema | Si | Si | Si | Si |

### Servicio × Broker

| Broker | springboot | quarkus | go | node |
|---|---|---|---|---|
| Kafka | Si | Si | Si | Si |
| RabbitMQ | Si | Si | Si | Si |
| NATS | Si | Si | Si | Si |

### Combinaciones totales

- 4 servicios × 7 protocolos × 3 brokers = **84 combinaciones**
- Cada combinación implica un test de publicación + consumo entre al menos 2 servicios.

---

## 8. Docker Compose

La infraestructura se orquesta con Docker Compose. Se divide en dos perfiles:

### Perfil `infra` — Infraestructura

```yaml
services:
  postgres:       # PostgreSQL 16
  zookeeper:      # Dependencia de Kafka
  kafka:          # Apache Kafka
  rabbitmq:       # RabbitMQ + Management UI
  nats:           # NATS
```

### Perfil `app` — Servicios de aplicación

```yaml
services:
  service-springboot:
    build: ./service-springboot
    ports: ["8081:8081"]
    depends_on: [postgres, kafka, rabbitmq, nats]

  service-quarkus:
    build: ./service-quarkus
    ports: ["8082:8082"]
    depends_on: [postgres, kafka, rabbitmq, nats]

  service-go:
    build: ./service-go
    ports: ["8083:8083"]
    depends_on: [postgres, kafka, rabbitmq, nats]

  service-node:
    build: ./service-node
    ports: ["8084:8084"]
    depends_on: [postgres, kafka, rabbitmq, nats]
```

### Comandos principales

```bash
# Levantar solo infraestructura
docker compose --profile infra up -d

# Levantar todo
docker compose --profile infra --profile app up -d

# Ver logs de un servicio
docker compose logs -f service-go

# Parar todo
docker compose down
```

---

## Diagrama de alto nivel

```
┌─────────────────────────────────────────────────────┐
│                     serialplab                       │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌────────┐  │
│  │springboot│ │ quarkus  │ │   go   │ │  node  │  │
│  │  :8081   │ │  :8082   │ │ :8083  │ │ :8084  │  │
│  └────┬─────┘ └────┬─────┘ └───┬────┘ └───┬────┘  │
│       │             │           │           │       │
│       └─────────────┴─────┬─────┴───────────┘       │
│                           │                         │
│              ┌────────────┴────────────┐            │
│              │   Serialización (x7)    │            │
│              │ protobuf, avro, thrift, │            │
│              │ msgpack, flatbuf, cbor, │            │
│              │ json-schema             │            │
│              └────────────┬────────────┘            │
│                           │                         │
│            ┌──────────────┼──────────────┐          │
│            │              │              │          │
│         ┌──┴──┐      ┌───┴───┐      ┌───┴──┐      │
│         │Kafka│      │Rabbit │      │ NATS │      │
│         │9092 │      │ 5672  │      │ 4222 │      │
│         └─────┘      └───────┘      └──────┘      │
│                           │                         │
│                    ┌──────┴──────┐                  │
│                    │ PostgreSQL  │                  │
│                    │    5432     │                  │
│                    └─────────────┘                  │
└─────────────────────────────────────────────────────┘
```

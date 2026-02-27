# Servicios — serialplab

Cada servicio implementa los 7 protocolos de serialización y se conecta a los 3 brokers de mensajería.

## Índice

| Servicio | Stack | Puerto | Spec |
|---|---|---|---|
| `service-springboot` | Java 21 + Spring Boot 3 | 8081 | [service-springboot.md](service-springboot.md) |
| `service-quarkus` | Java 21 + Quarkus | 8082 | [service-quarkus.md](service-quarkus.md) |
| `service-go` | Go 1.22+ | 8083 | [service-go.md](service-go.md) |
| `service-node` | Node.js 22 + Express/Fastify | 8084 | [service-node.md](service-node.md) |

## Características comunes

- Publican y consumen mensajes en todos los brokers configurados.
- Soportan los 7 protocolos de serialización.
- Exponen `/health` para readiness/liveness probes.
- Se conectan a PostgreSQL con su propio schema.

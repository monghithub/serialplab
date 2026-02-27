# CBOR

## Descripción

Concise Binary Object Representation. Estándar IETF (RFC 8949) para serialización binaria compacta. Diseñado como representación binaria de JSON, con soporte para tipos adicionales.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | No |
| Schema evolution | N/A (schema-less) |
| Zero-copy | No |
| Legible por humanos | No |

## Schema en el proyecto

No aplica — CBOR es schema-less (opcionalmente puede usar CDDL para validación).

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `com.fasterxml.jackson.dataformat:jackson-dataformat-cbor` | Integración Jackson |
| Quarkus | `com.fasterxml.jackson.dataformat:jackson-dataformat-cbor` | Integración Jackson |
| Go | `github.com/fxamacker/cbor/v2` | Conforme RFC 8949 |
| Node.js | `cbor-x` | Alternativa: `cbor` |

## Ventajas

- Estándar IETF, bien especificado.
- Más compacto que JSON.
- Soporta tipos que JSON no tiene (bytes, fechas, tags).
- No requiere schema ni code-gen.

## Limitaciones

- Sin schema no hay validación de estructura por defecto.
- Menos compacto que Protobuf/Avro para datos estructurados.
- Menos adoptado en ecosistemas de microservicios.

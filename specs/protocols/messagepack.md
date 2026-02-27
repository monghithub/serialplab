# MessagePack

## Descripción

Formato de serialización binaria eficiente, diseñado como un "JSON binario". Schema-less: no requiere definición previa de schema. Compatible con la mayoría de tipos de datos JSON.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | No |
| Schema evolution | N/A (schema-less) |
| Zero-copy | No |
| Legible por humanos | No |

## Schema en el proyecto

No aplica — MessagePack es schema-less.

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `org.msgpack:msgpack-core` | Alternativa: `jackson-dataformat-msgpack` |
| Quarkus | `org.msgpack:msgpack-core` | Alternativa: `jackson-dataformat-msgpack` |
| Go | `github.com/vmihailenco/msgpack/v5` | Alternativa: `github.com/tinylib/msgp` |
| Node.js | `@msgpack/msgpack` | Alternativa: `msgpack-lite` |

## Ventajas

- Sin schema: serialización directa de objetos.
- Más compacto que JSON.
- Muy rápido en serialización/deserialización.
- Amplio soporte multi-lenguaje.

## Limitaciones

- Sin schema no hay validación de estructura.
- No soporta schema evolution (cambios requieren coordinación manual).
- Menos compacto que Protobuf/Avro para mensajes con schema.

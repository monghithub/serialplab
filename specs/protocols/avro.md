# Apache Avro

## Descripción

Formato de serialización binaria del ecosistema Apache. Schema evolution nativa y uso común con Kafka (Schema Registry). El schema se define en JSON.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | Sí (JSON schema, `.avsc`) |
| Schema evolution | Sí (nativa, reglas de compatibilidad) |
| Zero-copy | No |
| Legible por humanos | No (datos); Sí (schema) |

## Schema en el proyecto

```
schemas/avro/message.avsc
```

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `org.apache.avro:avro` | Plugin Maven `avro-maven-plugin` |
| Quarkus | `org.apache.avro:avro` | Plugin Maven `avro-maven-plugin` |
| Go | `github.com/linkedin/goavro/v2` | Encoding/decoding dinámico |
| Node.js | `avsc` | Parsing de schema y (de)serialización |

## Ventajas

- Schema evolution con reglas de compatibilidad (forward, backward, full).
- Integración nativa con Confluent Schema Registry.
- Schema en JSON, fácil de versionar.
- Compacto: no incluye nombres de campo en el payload.

## Limitaciones

- Requiere el schema del writer para deserializar.
- Menos soporte multi-lenguaje que Protobuf.
- Code-gen opcional pero recomendado para rendimiento.

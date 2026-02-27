# JSON Schema

## Descripción

Serialización en texto (JSON) con validación mediante JSON Schema. Sirve como baseline de comparación frente a los formatos binarios. Legible por humanos.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Texto (JSON) |
| Schema obligatorio | Sí (JSON Schema) |
| Schema evolution | Manual (versionado de schemas) |
| Zero-copy | No |
| Legible por humanos | Sí |

## Schema en el proyecto

```
schemas/jsonschema/message.schema.json
```

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `com.networknt:json-schema-validator` | Alternativa: Jackson para serialización |
| Quarkus | `com.networknt:json-schema-validator` | Alternativa: Jackson / JSON-B |
| Go | `github.com/santhosh-tekuri/jsonschema/v5` | Serialización con `encoding/json` (stdlib) |
| Node.js | `ajv` | Validador JSON Schema más usado en npm |

## Ventajas

- Legible por humanos: fácil de depurar e inspeccionar.
- Soporte universal en todos los lenguajes.
- Sin code-gen: uso directo de maps/objetos nativos.
- JSON Schema permite validación rigurosa.

## Limitaciones

- Mayor tamaño de payload que formatos binarios.
- Serialización/deserialización más lenta.
- Sin schema evolution automática.
- No apto para escenarios de alto throughput.

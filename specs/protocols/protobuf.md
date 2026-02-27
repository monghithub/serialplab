# Protocol Buffers (Protobuf)

## Descripción

Formato de serialización binaria desarrollado por Google. Estándar de facto en gRPC. Requiere definición de schema en archivos `.proto` y genera código para múltiples lenguajes.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | Sí (`.proto`) |
| Schema evolution | Sí (campos opcionales, numeración) |
| Zero-copy | No |
| Legible por humanos | No |

## Schema en el proyecto

```
schemas/protobuf/message.proto
```

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `com.google.protobuf:protobuf-java` | Plugin Maven para code-gen |
| Quarkus | `com.google.protobuf:protobuf-java` | Plugin Maven para code-gen |
| Go | `google.golang.org/protobuf` | `protoc-gen-go` para code-gen |
| Node.js | `protobufjs` | Code-gen o reflexión dinámica |

## Ventajas

- Excelente rendimiento de serialización/deserialización.
- Schema evolution robusta con compatibilidad hacia atrás y adelante.
- Amplio soporte multi-lenguaje.
- Estándar en gRPC, extenso ecosistema.

## Limitaciones

- Requiere paso de code-gen en el build.
- No legible por humanos (binario).
- Schema obligatorio puede añadir fricción en prototipado.

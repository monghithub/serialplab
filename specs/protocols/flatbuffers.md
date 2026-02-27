# FlatBuffers

## Descripción

Formato de serialización binaria desarrollado por Google, optimizado para acceso zero-copy. Permite leer campos individuales sin deserializar todo el mensaje.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | Sí (`.fbs`) |
| Schema evolution | Sí (campos opcionales, deprecación) |
| Zero-copy | Sí |
| Legible por humanos | No |

## Schema en el proyecto

```
schemas/flatbuffers/message.fbs
```

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `com.google.flatbuffers:flatbuffers-java` | Compilador `flatc` para code-gen |
| Quarkus | `com.google.flatbuffers:flatbuffers-java` | Compilador `flatc` para code-gen |
| Go | `github.com/google/flatbuffers/go` | Compilador `flatc` para code-gen |
| Node.js | `flatbuffers` | Compilador `flatc` para code-gen |

## Ventajas

- Zero-copy: acceso a campos sin deserialización completa.
- Muy eficiente en memoria (sin allocations intermedias).
- Ideal para mensajes grandes donde solo se leen algunos campos.
- Schema evolution con compatibilidad hacia atrás.

## Limitaciones

- API más verbosa que Protobuf.
- Construcción de mensajes requiere builder pattern.
- Menos adoptado que Protobuf en la industria.
- Mutabilidad limitada del buffer serializado.

# Apache Thrift

## Descripción

Framework de serialización y RPC desarrollado originalmente en Facebook. IDL propia que genera código multi-lenguaje. Soporta múltiples protocolos de transporte y serialización.

## Características

| Propiedad | Valor |
|---|---|
| Formato | Binario |
| Schema obligatorio | Sí (`.thrift`) |
| Schema evolution | Parcial (campos opcionales, IDs numéricos) |
| Zero-copy | No |
| Legible por humanos | No |

## Schema en el proyecto

```
schemas/thrift/message.thrift
```

## Librerías por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `org.apache.thrift:libthrift` | Compilador `thrift` para code-gen |
| Quarkus | `org.apache.thrift:libthrift` | Compilador `thrift` para code-gen |
| Go | `github.com/apache/thrift/lib/go/thrift` | Compilador `thrift` para code-gen |
| Node.js | `thrift` | Compilador `thrift` para code-gen |

## Ventajas

- Framework completo: serialización + RPC + transporte.
- Múltiples protocolos de serialización (Binary, Compact, JSON).
- Generación de código multi-lenguaje desde una IDL.

## Limitaciones

- Schema evolution menos flexible que Protobuf/Avro.
- Ecosistema menos activo que Protobuf.
- Compilador Thrift necesario como dependencia de build.

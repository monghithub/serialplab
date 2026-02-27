# Tarea: Crear schemas protobuf, avro y thrift del modelo User

## Issue: #2
## Subtarea: 1 de 2

## Objetivo

Crear 3 ficheros de schema que definen el modelo `User` en formatos Protobuf, Avro y Thrift.

## Ficheros a crear

- `schemas/protobuf/message.proto`
- `schemas/avro/message.avsc`
- `schemas/thrift/message.thrift`

## Contexto

El modelo **User** tiene 4 campos:

| Campo | Tipo lógico | Protobuf | Avro | Thrift |
|-------|------------|----------|------|--------|
| id | UUID (string) | `string` | `"type": "string"` | `string` |
| name | string | `string` | `"type": "string"` | `string` |
| email | string | `string` | `"type": "string"` | `string` |
| timestamp | epoch ms (long) | `int64` | `"type": "long"` | `i64` |

### Protobuf (`schemas/protobuf/message.proto`)

```protobuf
syntax = "proto3";

package serialplab;

option java_package = "com.serialplab.proto";
option go_package = "serialplab/proto";

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int64 timestamp = 4;
}
```

### Avro (`schemas/avro/message.avsc`)

```json
{
  "type": "record",
  "name": "User",
  "namespace": "com.serialplab.avro",
  "fields": [
    {"name": "id", "type": "string", "doc": "UUID del usuario"},
    {"name": "name", "type": "string", "doc": "Nombre del usuario"},
    {"name": "email", "type": "string", "doc": "Email del usuario"},
    {"name": "timestamp", "type": "long", "doc": "Epoch milliseconds"}
  ]
}
```

### Thrift (`schemas/thrift/message.thrift`)

```thrift
namespace java com.serialplab.thrift
namespace go serialplab.thrift

struct User {
  1: required string id,
  2: required string name,
  3: required string email,
  4: required i64 timestamp,
}
```

## Criterios de aceptación

- [ ] Los 3 ficheros existen en sus directorios correspondientes
- [ ] Cada schema define User con los 4 campos (id, name, email, timestamp)
- [ ] Los tipos son coherentes entre schemas

## Validación

```bash
test -f schemas/protobuf/message.proto && test -f schemas/avro/message.avsc && test -f schemas/thrift/message.thrift && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados, INCLUSO si la validación falla.

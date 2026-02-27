# Tarea: Crear schemas flatbuffers y json-schema del modelo User

## Issue: #2
## Subtarea: 2 de 2

## Objetivo

Crear 2 ficheros de schema que definen el modelo `User` en formatos FlatBuffers y JSON Schema.

## Ficheros a crear

- `schemas/flatbuffers/message.fbs`
- `schemas/jsonschema/message.schema.json`

## Contexto

El modelo **User** tiene 4 campos:

| Campo | Tipo lógico | FlatBuffers | JSON Schema |
|-------|------------|-------------|-------------|
| id | UUID (string) | `string` | `"type": "string", "format": "uuid"` |
| name | string | `string` | `"type": "string"` |
| email | string | `string` | `"type": "string", "format": "email"` |
| timestamp | epoch ms (long) | `long` | `"type": "integer"` |

### FlatBuffers (`schemas/flatbuffers/message.fbs`)

```flatbuffers
namespace serialplab.flatbuf;

table User {
  id:string;
  name:string;
  email:string;
  timestamp:long;
}

root_type User;
```

### JSON Schema (`schemas/jsonschema/message.schema.json`)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://serialplab.example.com/schemas/user.json",
  "title": "User",
  "description": "Modelo compartido User de serialplab",
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "format": "uuid",
      "description": "UUID del usuario"
    },
    "name": {
      "type": "string",
      "description": "Nombre del usuario"
    },
    "email": {
      "type": "string",
      "format": "email",
      "description": "Email del usuario"
    },
    "timestamp": {
      "type": "integer",
      "description": "Epoch milliseconds"
    }
  },
  "required": ["id", "name", "email", "timestamp"],
  "additionalProperties": false
}
```

## Criterios de aceptación

- [ ] Los 2 ficheros existen en sus directorios correspondientes
- [ ] Cada schema define User con los 4 campos (id, name, email, timestamp)
- [ ] Los tipos son coherentes con los schemas de la subtarea 1

## Validación

```bash
test -f schemas/flatbuffers/message.fbs && test -f schemas/jsonschema/message.schema.json && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados, INCLUSO si la validación falla.

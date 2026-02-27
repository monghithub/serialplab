# Specs — Registros

Specs de los registros de schemas y APIs utilizados en serialplab.

## Contenido

| Registro | Descripción | Doc técnica |
|---|---|---|
| [Apicurio Registry](apicurio-registry.md) | Registro centralizado de schemas y APIs | [doc](../../doc/registros/apicurio-registry.md) |

## Rol en el proyecto

Los registros de schemas centralizan la gestión de definiciones de datos (Avro, Protobuf, JSON Schema), proporcionando:

- Almacenamiento centralizado de schemas
- Versionado y evolución controlada
- Validación de compatibilidad entre versiones
- API para que producers y consumers obtengan schemas en runtime

# Specs — Frontend

Specs de los frontends del proyecto serialplab. Cada spec describe la aplicación, su stack, los endpoints que consume y la interacción con los servicios backend.

## Contenido

| Aplicación | Stack | Puerto | Spec |
|---|---|---|---|
| `frontend-angular` | Angular 19 + TypeScript | 11000 | [frontend-angular.md](frontend-angular.md) |

## Rol del frontend

El frontend actúa como capa de orquestación que permite al usuario:

1. Seleccionar **servicio origen** (quién envía la petición HTTP).
2. Seleccionar **servicio destino** (parámetro `{target}` del POST).
3. Elegir **protocolo de serialización** y **broker de mensajería**.
4. Ejecutar operaciones CRUD de usuario sobre la combinación elegida.

Ver [ARCHITECTURE.md](../../ARCHITECTURE.md) para la visión general del proyecto.

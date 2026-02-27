# frontend-angular

## Descripción

Frontend web basado en **Angular 19 + TypeScript** que orquesta las peticiones HTTP entre los servicios backend de serialplab. Permite al usuario seleccionar combinaciones de servicio origen, servicio destino, protocolo de serialización y broker de mensajería para ejecutar operaciones CRUD de usuario.

## Stack tecnológico

| Propiedad | Valor |
|---|---|
| Framework | Angular 19 |
| Lenguaje | TypeScript |
| Puerto | 11000 |
| Build | Angular CLI (`ng build`) |
| Styling | Angular Material / CSS |

## Modelo de datos

### User

```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "createdAt": "datetime"
}
```

Todas las operaciones CRUD utilizan este mismo modelo independientemente de la combinación seleccionada.

## Servicios backend consumidos

| Servicio | Base URL | Spec |
|---|---|---|
| `service-springboot` | `http://service-springboot:11001` | [service-springboot.md](../services/service-springboot.md) |
| `service-quarkus` | `http://service-quarkus:11002` | [service-quarkus.md](../services/service-quarkus.md) |
| `service-go` | `http://service-go:11003` | [service-go.md](../services/service-go.md) |
| `service-node` | `http://service-node:11004` | [service-node.md](../services/service-node.md) |

## Endpoints consumidos

El frontend envía peticiones al servicio origen seleccionado. El endpoint tiene la forma:

```
POST http://{servicio-origen}:{puerto}/publish/{target}/{protocol}/{broker}
```

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/publish/{target}/{protocol}/{broker}` | Publica mensaje al servicio destino con protocolo y broker indicados |
| GET | `/messages` | Lista mensajes recibidos por el servicio |
| GET | `/health` | Health check del servicio |

### Parámetros

| Parámetro | Valores posibles |
|---|---|
| `{target}` | `service-springboot`, `service-quarkus`, `service-go`, `service-node` |
| `{protocol}` | `protobuf`, `avro`, `thrift`, `messagepack`, `flatbuffers`, `cbor`, `json-schema` |
| `{broker}` | `kafka`, `rabbitmq`, `nats` |

## Componentes principales

### Dashboard (`/`)

Página principal con vista general del sistema: estado de los servicios (health checks) y acceso rápido a las operaciones CRUD.

### Selector de configuración

Componente reutilizable que permite elegir:

- **Servicio origen**: dropdown con los 4 servicios backend.
- **Servicio destino**: dropdown con los 4 servicios backend (excluyendo el origen).
- **Protocolo**: dropdown con los 7 protocolos de serialización.
- **Broker**: dropdown con los 3 brokers de mensajería.

### Formulario CRUD (`/crud`)

Formulario para operaciones sobre el modelo User:

| Operación | Acción HTTP | Descripción |
|---|---|---|
| Crear | POST `/publish/{target}/{protocol}/{broker}` | Envía un User nuevo |
| Listar | GET `/messages` | Lista los mensajes/usuarios recibidos |
| Obtener | GET `/messages/{id}` | Obtiene un mensaje/usuario por ID |
| Eliminar | DELETE `/messages/{id}` | Elimina un mensaje/usuario |

### Tabla de resultados

Muestra los resultados de las operaciones en formato tabular con los campos del modelo User (`id`, `name`, `email`, `createdAt`).

## Routing

| Ruta | Componente | Descripción |
|---|---|---|
| `/` | Dashboard | Vista general y health checks |
| `/crud` | CRUD | Formulario y tabla de operaciones |

## Servicios Angular

### `ApiService`

Servicio principal que gestiona las peticiones HTTP. Construye dinámicamente la URL base según el servicio origen seleccionado.

```typescript
// Ejemplo de construcción de URL
const baseUrl = `http://${selectedService.host}:${selectedService.port}`;
const publishUrl = `${baseUrl}/publish/${target}/${protocol}/${broker}`;
```

### `ConfigService`

Gestiona la configuración de servicios disponibles, protocolos y brokers. Provee las opciones para los selectores del UI.

### `HealthService`

Realiza health checks periódicos a los 4 servicios backend y expone su estado al dashboard.

## Flujo de ejemplo

1. El usuario abre el dashboard y verifica que los servicios están activos.
2. Navega a `/crud` y selecciona la configuración:
   - **Origen:** `service-springboot` (`:11001`)
   - **Destino:** `service-go`
   - **Protocolo:** `avro`
   - **Broker:** `kafka`
3. Rellena el formulario con datos de un User (`name`, `email`).
4. Al enviar, el frontend ejecuta:
   ```
   POST http://service-springboot:11001/publish/service-go/avro/kafka
   Body: { "name": "Ana", "email": "ana@example.com" }
   ```
5. El servicio springboot serializa con Avro, publica en Kafka, y el servicio go consume el mensaje.
6. La tabla de resultados muestra la respuesta del servicio.

## Docker

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration=production

FROM nginx:alpine
COPY --from=build /app/dist/frontend-angular/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 11000
```

## Documentación de referencia

- [doc Angular](../../doc/frontend/angular.md)
- [doc Node.js + TypeScript](../../doc/lenguajes/nodejs-typescript.md)

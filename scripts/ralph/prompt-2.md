# Tarea: Crear Dockerfiles stub y perfil app

## Issue: #1
## Subtarea: 2 de 2

## Objetivo

Crear Dockerfiles mínimos (stub) para los 5 servicios de aplicación y añadir el perfil `app` al `docker-compose.yml` existente. Cada stub solo necesita responder a `/health` con un 200.

## Ficheros a crear/modificar

- `docker-compose.yml` (añadir perfil app)
- `frontend-angular/Dockerfile`
- `service-springboot/Dockerfile`
- `service-quarkus/Dockerfile`
- `service-go/Dockerfile`
- `service-node/Dockerfile`

## Contexto

Los Dockerfiles stub sirven para validar que docker-compose levanta todo. Cada uno debe:
1. Usar una imagen base ligera (alpine o similar)
2. Exponer su puerto
3. Responder GET `/health` con `{"status":"ok"}` en su puerto asignado

### Stubs recomendados

Usar `python:3-alpine` con un one-liner HTTP server para todos:

```dockerfile
FROM python:3-alpine
EXPOSE {puerto}
CMD ["python", "-c", "from http.server import HTTPServer, BaseHTTPRequestHandler; import json;\nclass H(BaseHTTPRequestHandler):\n def do_GET(self):\n  self.send_response(200)\n  self.send_header('Content-Type','application/json')\n  self.end_headers()\n  self.wfile.write(json.dumps({'status':'ok'}).encode())\nHTTPServer(('',{puerto}),H).serve_forever()"]
```

Alternativamente, usar un script `healthcheck.py` que copias al contenedor.

### Puertos

| Servicio | Puerto |
|----------|--------|
| frontend-angular | 11000 |
| service-springboot | 11001 |
| service-quarkus | 11002 |
| service-go | 11003 |
| service-node | 11004 |

### Perfil app en docker-compose.yml

Añadir al `docker-compose.yml` existente (NO sobrescribir el perfil infra):

```yaml
  frontend-angular:
    build: ./frontend-angular
    profiles: ["app"]
    ports:
      - "11000:11000"
    depends_on:
      - service-springboot
      - service-quarkus
      - service-go
      - service-node

  service-springboot:
    build: ./service-springboot
    profiles: ["app"]
    ports:
      - "11001:11001"
    depends_on:
      postgres:
        condition: service_healthy

  service-quarkus:
    build: ./service-quarkus
    profiles: ["app"]
    ports:
      - "11002:11002"
    depends_on:
      postgres:
        condition: service_healthy

  service-go:
    build: ./service-go
    profiles: ["app"]
    ports:
      - "11003:11003"
    depends_on:
      postgres:
        condition: service_healthy

  service-node:
    build: ./service-node
    profiles: ["app"]
    ports:
      - "11004:11004"
    depends_on:
      postgres:
        condition: service_healthy
```

## Criterios de aceptación

- [ ] 5 directorios creados con su Dockerfile
- [ ] Cada Dockerfile responde GET en su puerto con `{"status":"ok"}`
- [ ] `docker compose config --profiles infra --profiles app` valida sin errores
- [ ] Los servicios app dependen de postgres

## Validación

```bash
docker compose config --profiles infra --profiles app
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`. Si necesitas instalar algo con sudo, crea una GitHub Issue con `gh issue create --title "Instalar {paquete}" --body "Se necesita: {detalle}"` y marca esta subtarea como bloqueada.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados, INCLUSO si la validación falla. El código se corregirá en la siguiente iteración.

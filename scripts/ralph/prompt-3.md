# Tarea: Dockerfile + nginx.conf

## Issue: #7
## Subtarea: 3 de 3

## Objetivo

Crear el Dockerfile multi-stage con nginx y la configuración de nginx para la SPA Angular.

## Ficheros a crear

- `frontend-angular/nginx.conf`
- `frontend-angular/Dockerfile`

## Contexto

### nginx.conf

Sirve la SPA en el puerto 11000 y redirige rutas desconocidas a index.html (SPA routing).

```nginx
server {
    listen 11000;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        # Proxy pass to backend services will be configured later
        return 502;
    }
}
```

### Dockerfile

Multi-stage: build con Node.js, serve con nginx.

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build -- --configuration=production

FROM nginx:alpine
COPY --from=build /app/dist/frontend-angular/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 11000
```

## Validación

```bash
test -f frontend-angular/nginx.conf && test -f frontend-angular/Dockerfile && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

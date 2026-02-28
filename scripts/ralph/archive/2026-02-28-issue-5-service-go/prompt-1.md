# Tarea: package.json + tsconfig + Express app con health endpoint

## Issue: #6
## Subtarea: 1 de 2

## Objetivo

Crear el proyecto Node.js 22 + TypeScript con Express, package.json, tsconfig.json y el entry point con health endpoint.

## Ficheros a crear

- `service-node/package.json`
- `service-node/tsconfig.json`
- `service-node/src/index.ts`

## Contexto

### package.json

```json
{
  "name": "service-node",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "ts-node src/index.ts"
  },
  "dependencies": {
    "express": "^4.21.2",
    "pg": "^8.13.1",
    "kafkajs": "^2.2.4",
    "amqplib": "^0.10.5",
    "nats": "^2.29.1",
    "@msgpack/msgpack": "^3.0.0-beta2",
    "cbor-x": "^1.6.0"
  },
  "devDependencies": {
    "typescript": "^5.7.3",
    "@types/express": "^5.0.0",
    "@types/pg": "^8.11.11",
    "@types/amqplib": "^0.10.6",
    "ts-node": "^10.9.2"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### src/index.ts

```typescript
import express from 'express';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

const PORT = 11004;
app.listen(PORT, () => {
  console.log(`service-node starting on :${PORT}`);
});

export default app;
```

## Validación

```bash
test -f service-node/package.json && test -f service-node/tsconfig.json && test -f service-node/src/index.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

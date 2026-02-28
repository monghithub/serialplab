# Tarea: DB, serialización, brokers y handlers + Dockerfile

## Issue: #6
## Subtarea: 2 de 2

## Objetivo

Crear los módulos de base de datos, serialización, brokers, los handlers de publish/messages, actualizar index.ts con las rutas, y crear el Dockerfile.

## Ficheros a crear

- `service-node/src/db.ts`
- `service-node/src/serialization.ts`
- `service-node/src/broker.ts`
- `service-node/src/routes.ts`
- `service-node/Dockerfile`

## Ficheros a modificar

- `service-node/src/index.ts` (añadir import de routes)

## Contexto

### db.ts

PostgreSQL con schema `node`.

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: 'localhost',
  port: 11010,
  user: 'serialplab',
  password: 'serialplab',
  database: 'serialplab',
});

export async function initDb(): Promise<void> {
  try {
    await pool.query('CREATE SCHEMA IF NOT EXISTS node');
    await pool.query(`CREATE TABLE IF NOT EXISTS node.message_log (
      id SERIAL PRIMARY KEY,
      direction TEXT, protocol TEXT, broker TEXT, target_service TEXT,
      user_id TEXT, user_name TEXT, user_email TEXT, user_timestamp BIGINT,
      created_at TIMESTAMP DEFAULT NOW()
    )`);
  } catch (err) {
    console.warn('DB init warning:', err);
  }
}

export async function saveMessage(msg: {
  direction: string; protocol: string; broker: string; targetService: string;
  userId: string; userName: string; userEmail: string; userTimestamp: number;
}): Promise<void> {
  await pool.query(
    'INSERT INTO node.message_log (direction, protocol, broker, target_service, user_id, user_name, user_email, user_timestamp) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)',
    [msg.direction, msg.protocol, msg.broker, msg.targetService, msg.userId, msg.userName, msg.userEmail, msg.userTimestamp]
  );
}

export async function getMessages(): Promise<any[]> {
  const result = await pool.query('SELECT * FROM node.message_log ORDER BY created_at DESC');
  return result.rows;
}
```

### serialization.ts

```typescript
import { encode as msgpackEncode, decode as msgpackDecode } from '@msgpack/msgpack';
import { encode as cborEncode, decode as cborDecode } from 'cbor-x';

export interface User {
  id: string;
  name: string;
  email: string;
  timestamp: number;
}

export function serialize(protocol: string, user: User): Buffer {
  switch (protocol.toLowerCase()) {
    case 'json':
    case 'json-schema':
      return Buffer.from(JSON.stringify(user));
    case 'cbor':
      return Buffer.from(cborEncode(user));
    case 'msgpack':
    case 'messagepack':
      return Buffer.from(msgpackEncode(user));
    case 'protobuf':
    case 'avro':
    case 'thrift':
    case 'flatbuffers':
      return Buffer.from(JSON.stringify(user)); // placeholder
    default:
      throw new Error(`Unknown protocol: ${protocol}`);
  }
}

export function deserialize(protocol: string, data: Buffer): User {
  switch (protocol.toLowerCase()) {
    case 'json':
    case 'json-schema':
      return JSON.parse(data.toString());
    case 'cbor':
      return cborDecode(data) as User;
    case 'msgpack':
    case 'messagepack':
      return msgpackDecode(data) as User;
    case 'protobuf':
    case 'avro':
    case 'thrift':
    case 'flatbuffers':
      return JSON.parse(data.toString()); // placeholder
    default:
      throw new Error(`Unknown protocol: ${protocol}`);
  }
}
```

### broker.ts

```typescript
import { Kafka } from 'kafkajs';
import amqplib from 'amqplib';
import { connect as natsConnect } from 'nats';

export async function publish(brokerName: string, target: string, protocol: string, data: Buffer): Promise<void> {
  const subject = `serialplab.${target}.${protocol}`;
  switch (brokerName.toLowerCase()) {
    case 'kafka':
      return publishKafka(subject, data);
    case 'rabbitmq':
      return publishRabbit(subject, data);
    case 'nats':
      return publishNats(subject, data);
    default:
      throw new Error(`Unknown broker: ${brokerName}`);
  }
}

async function publishKafka(topic: string, data: Buffer): Promise<void> {
  const kafka = new Kafka({ brokers: ['localhost:11021'] });
  const producer = kafka.producer();
  await producer.connect();
  await producer.send({ topic, messages: [{ value: data }] });
  await producer.disconnect();
}

async function publishRabbit(routingKey: string, data: Buffer): Promise<void> {
  const conn = await amqplib.connect('amqp://guest:guest@localhost:11022');
  const ch = await conn.createChannel();
  ch.sendToQueue(routingKey, data);
  await ch.close();
  await conn.close();
}

async function publishNats(subject: string, data: Buffer): Promise<void> {
  const nc = await natsConnect({ servers: 'nats://localhost:11024' });
  nc.publish(subject, data);
  await nc.flush();
  await nc.close();
}
```

### routes.ts

```typescript
import { Router, Request, Response } from 'express';
import { serialize } from './serialization';
import { publish } from './broker';
import { saveMessage, getMessages } from './db';

const router = Router();

router.post('/publish/:target/:protocol/:broker', async (req: Request, res: Response) => {
  try {
    const { target, protocol, broker } = req.params;
    const user = req.body;
    const data = serialize(protocol, user);
    await publish(broker, target, protocol, data);

    await saveMessage({
      direction: 'sent', protocol, broker, targetService: target,
      userId: user.id, userName: user.name, userEmail: user.email, userTimestamp: user.timestamp,
    });

    res.json({ status: 'published', target, protocol, broker, bytes: data.length });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/messages', async (_req: Request, res: Response) => {
  try {
    const messages = await getMessages();
    res.json(messages);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
```

### index.ts COMPLETO (reemplaza el existente)

```typescript
import express from 'express';
import routes from './routes';
import { initDb } from './db';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use(routes);

const PORT = 11004;
initDb().then(() => {
  app.listen(PORT, () => {
    console.log(`service-node starting on :${PORT}`);
  });
});

export default app;
```

### Dockerfile

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
EXPOSE 11004
CMD ["node", "dist/index.js"]
```

## Validación

```bash
test -f service-node/src/db.ts && test -f service-node/src/serialization.ts && test -f service-node/src/broker.ts && test -f service-node/src/routes.ts && test -f service-node/Dockerfile && grep -q "routes" service-node/src/index.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

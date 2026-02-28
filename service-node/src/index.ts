import express from 'express';
import routes from './routes';
import { initDb, saveMessage } from './db';
import { startConsumers } from './consumer';
import { deserialize } from './serialization';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use(routes);

const PORT = 11004;
initDb().then(() => {
  startConsumers('service-node', (broker, protocol, data) => {
    try {
      const user = deserialize(protocol, data);
      console.log(`[${broker}/${protocol}] Received user: ${user.id}`);
      saveMessage({
        direction: 'in',
        protocol,
        broker,
        targetService: 'service-node',
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userTimestamp: user.timestamp,
      }).catch(err => console.error('saveMessage error:', err.message));
    } catch (err: any) {
      console.error(`[${broker}/${protocol}] Deserialization error:`, err.message);
    }
  });
  app.listen(PORT, () => {
    console.log(`service-node starting on :${PORT}`);
  });
});

export default app;
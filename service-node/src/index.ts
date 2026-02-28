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
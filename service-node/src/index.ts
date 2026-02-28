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
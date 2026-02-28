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
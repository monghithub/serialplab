import { Kafka } from 'kafkajs';
import amqplib from 'amqplib';
import { connect as natsConnect } from 'nats';

export type MessageHandler = (broker: string, protocol: string, data: Buffer) => void;

export async function startConsumers(serviceName: string, handler: MessageHandler): Promise<void> {
  consumeKafka(serviceName, handler).catch(err =>
    console.error('[Kafka] Consumer error:', err.message)
  );
  consumeRabbit(serviceName, handler).catch(err =>
    console.error('[RabbitMQ] Consumer error:', err.message)
  );
  consumeNats(serviceName, handler).catch(err =>
    console.error('[NATS] Consumer error:', err.message)
  );
}

async function consumeKafka(serviceName: string, handler: MessageHandler): Promise<void> {
  const kafka = new Kafka({ brokers: [process.env.KAFKA_BROKERS || 'localhost:11021'] });
  const consumer = kafka.consumer({ groupId: `${serviceName}-group` });
  await consumer.connect();
  await consumer.subscribe({ topics: [new RegExp(`serialplab\\.${serviceName}\\..*`)], fromBeginning: false });
  console.log(`[Kafka] Consuming topics: serialplab.${serviceName}.*`);
  await consumer.run({
    eachMessage: async ({ topic, message }) => {
      if (message.value) {
        const protocol = extractProtocol(topic);
        handler('kafka', protocol, message.value as Buffer);
      }
    },
  });
}

async function consumeRabbit(serviceName: string, handler: MessageHandler): Promise<void> {
  const conn = await amqplib.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:11022');
  const ch = await conn.createChannel();
  const queueName = `serialplab.${serviceName}.queue`;
  await ch.assertQueue(queueName, { durable: true });
  const bindKey = `serialplab.${serviceName}.*`;
  await ch.bindQueue(queueName, 'amq.topic', bindKey);
  console.log(`[RabbitMQ] Consuming queue: ${queueName}`);
  ch.consume(queueName, (msg) => {
    if (msg) {
      const protocol = extractProtocol(msg.fields.routingKey);
      handler('rabbitmq', protocol, msg.content);
      ch.ack(msg);
    }
  });
}

async function consumeNats(serviceName: string, handler: MessageHandler): Promise<void> {
  const nc = await natsConnect({ servers: process.env.NATS_URL || 'nats://localhost:11024' });
  const subject = `serialplab.${serviceName}.>`;
  console.log(`[NATS] Subscribing to: ${subject}`);
  const sub = nc.subscribe(subject);
  for await (const msg of sub) {
    const protocol = extractProtocol(msg.subject);
    handler('nats', protocol, Buffer.from(msg.data));
  }
}

function extractProtocol(subject: string): string {
  const parts = subject.split('.');
  return parts.length >= 3 ? parts[2] : 'json';
}
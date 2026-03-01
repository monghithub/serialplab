import { Kafka } from 'kafkajs';
import amqplib from 'amqplib';
import { connect as natsConnect, headers as natsHeaders } from 'nats';

export async function publish(brokerName: string, target: string, protocol: string, data: Buffer, origin: string): Promise<void> {
  const subject = `serialplab.${target}.${protocol}`;
  switch (brokerName.toLowerCase()) {
    case 'kafka':
      return publishKafka(subject, data, origin);
    case 'rabbitmq':
      return publishRabbit(subject, data, origin);
    case 'nats':
      return publishNats(subject, data, origin);
    default:
      throw new Error(`Unknown broker: ${brokerName}`);
  }
}

async function publishKafka(topic: string, data: Buffer, origin: string): Promise<void> {
  const kafka = new Kafka({ brokers: [process.env.KAFKA_BROKERS || 'localhost:11021'] });
  const producer = kafka.producer();
  await producer.connect();
  await producer.send({ topic, messages: [{ value: data, headers: { 'X-Origin': origin } }] });
  await producer.disconnect();
}

async function publishRabbit(routingKey: string, data: Buffer, origin: string): Promise<void> {
  const conn = await amqplib.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@localhost:11022');
  const ch = await conn.createChannel();
  ch.publish('amq.topic', routingKey, data, { headers: { 'X-Origin': origin } });
  await ch.close();
  await conn.close();
}

async function publishNats(subject: string, data: Buffer, origin: string): Promise<void> {
  const nc = await natsConnect({ servers: process.env.NATS_URL || 'nats://localhost:11024' });
  const h = natsHeaders();
  h.set('X-Origin', origin);
  nc.publish(subject, data, { headers: h });
  await nc.flush();
  await nc.close();
}

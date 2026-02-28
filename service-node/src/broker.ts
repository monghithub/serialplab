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
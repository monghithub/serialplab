# Tarea: Consume en service-go + service-node

## Issue: #22
## Subtarea: 2 de 2

## Objetivo

Añadir funcionalidad de consume/subscribe a los broker services de Go y Node.js.

## Ficheros a crear

- `service-go/internal/broker/consumer.go`
- `service-node/src/consumer.ts`

## Contexto

Topic pattern: `serialplab.{target}.{protocol}`. Cada servicio consume mensajes dirigidos a él.

### service-go/internal/broker/consumer.go

```go
package broker

import (
	"context"
	"fmt"
	"log"
	"strings"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/nats-io/nats.go"
	"github.com/segmentio/kafka-go"
)

type MessageHandler func(broker, protocol string, data []byte)

func StartConsumers(serviceName string, handler MessageHandler) {
	go consumeKafka(serviceName, handler)
	go consumeRabbit(serviceName, handler)
	go consumeNats(serviceName, handler)
}

func consumeKafka(serviceName string, handler MessageHandler) {
	topic := fmt.Sprintf("serialplab.%s.*", serviceName)
	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:   []string{"localhost:11021"},
		Topic:     topic,
		GroupID:   serviceName + "-group",
		Partition: 0,
		MinBytes:  1,
		MaxBytes:  10e6,
	})
	defer r.Close()
	log.Printf("[Kafka] Consuming topic pattern: %s", topic)
	for {
		msg, err := r.ReadMessage(context.Background())
		if err != nil {
			log.Printf("[Kafka] Read error: %v", err)
			return
		}
		protocol := extractProtocol(msg.Topic)
		handler("kafka", protocol, msg.Value)
	}
}

func consumeRabbit(serviceName string, handler MessageHandler) {
	conn, err := amqp.Dial("amqp://guest:guest@localhost:11022/")
	if err != nil {
		log.Printf("[RabbitMQ] Connection failed: %v", err)
		return
	}
	defer conn.Close()
	ch, err := conn.Channel()
	if err != nil {
		log.Printf("[RabbitMQ] Channel failed: %v", err)
		return
	}
	defer ch.Close()
	queueName := fmt.Sprintf("serialplab.%s.queue", serviceName)
	q, err := ch.QueueDeclare(queueName, true, false, false, false, nil)
	if err != nil {
		log.Printf("[RabbitMQ] Queue declare failed: %v", err)
		return
	}
	// Bind to all routing keys matching the service
	bindKey := fmt.Sprintf("serialplab.%s.*", serviceName)
	ch.QueueBind(q.Name, bindKey, "amq.topic", false, nil)
	msgs, err := ch.Consume(q.Name, "", true, false, false, false, nil)
	if err != nil {
		log.Printf("[RabbitMQ] Consume failed: %v", err)
		return
	}
	log.Printf("[RabbitMQ] Consuming queue: %s", queueName)
	for msg := range msgs {
		protocol := extractProtocol(msg.RoutingKey)
		handler("rabbitmq", protocol, msg.Body)
	}
}

func consumeNats(serviceName string, handler MessageHandler) {
	nc, err := nats.Connect("nats://localhost:11024")
	if err != nil {
		log.Printf("[NATS] Connection failed: %v", err)
		return
	}
	subject := fmt.Sprintf("serialplab.%s.>", serviceName)
	log.Printf("[NATS] Subscribing to: %s", subject)
	nc.Subscribe(subject, func(msg *nats.Msg) {
		protocol := extractProtocol(msg.Subject)
		handler("nats", protocol, msg.Data)
	})
	// Block forever
	select {}
}

func extractProtocol(subject string) string {
	parts := strings.Split(subject, ".")
	if len(parts) >= 3 {
		return parts[2]
	}
	return "json"
}
```

### service-node/src/consumer.ts

```typescript
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
  const kafka = new Kafka({ brokers: ['localhost:11021'] });
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
  const conn = await amqplib.connect('amqp://guest:guest@localhost:11022');
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
  const nc = await natsConnect({ servers: 'nats://localhost:11024' });
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
```

## Validación

```bash
test -f service-go/internal/broker/consumer.go && test -f service-node/src/consumer.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

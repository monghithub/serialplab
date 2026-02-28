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
	protocols := []string{"protobuf", "avro", "thrift", "messagepack", "flatbuffers", "cbor", "json-schema"}
	for _, protocol := range protocols {
		proto := protocol
		topic := fmt.Sprintf("serialplab.%s.%s", serviceName, proto)
		go func() {
			r := kafka.NewReader(kafka.ReaderConfig{
				Brokers:  []string{"localhost:11021"},
				Topic:    topic,
				GroupID:  serviceName + "-group",
				MinBytes: 1,
				MaxBytes: 10e6,
			})
			defer r.Close()
			log.Printf("[Kafka] Consuming topic: %s", topic)
			for {
				msg, err := r.ReadMessage(context.Background())
				if err != nil {
					log.Printf("[Kafka] Read error on %s: %v", topic, err)
					return
				}
				handler("kafka", proto, msg.Value)
			}
		}()
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
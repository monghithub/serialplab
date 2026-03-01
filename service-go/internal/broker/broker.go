package broker

import (
	"context"
	"fmt"
	"os"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/nats-io/nats.go"
	"github.com/segmentio/kafka-go"
)

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func Publish(brokerName, target, protocol string, data []byte, origin string) error {
	subject := fmt.Sprintf("serialplab.%s.%s", target, protocol)
	switch brokerName {
	case "kafka":
		return publishKafka(subject, data, origin)
	case "rabbitmq":
		return publishRabbit(subject, data, origin)
	case "nats":
		return publishNats(subject, data, origin)
	default:
		return fmt.Errorf("unknown broker: %s", brokerName)
	}
}

func publishKafka(topic string, data []byte, origin string) error {
	w := &kafka.Writer{
		Addr:  kafka.TCP(envOrDefault("KAFKA_BROKERS", "localhost:11021")),
		Topic: topic,
	}
	defer w.Close()
	return w.WriteMessages(context.Background(), kafka.Message{
		Value: data,
		Headers: []kafka.Header{{Key: "X-Origin", Value: []byte(origin)}},
	})
}

func publishRabbit(routingKey string, data []byte, origin string) error {
	conn, err := amqp.Dial(envOrDefault("RABBITMQ_URL", "amqp://guest:guest@localhost:11022/"))
	if err != nil {
		return err
	}
	defer conn.Close()
	ch, err := conn.Channel()
	if err != nil {
		return err
	}
	defer ch.Close()
	return ch.Publish("amq.topic", routingKey, false, false, amqp.Publishing{
		Body:    data,
		Headers: amqp.Table{"X-Origin": origin},
	})
}

func publishNats(subject string, data []byte, origin string) error {
	nc, err := nats.Connect(envOrDefault("NATS_URL", "nats://localhost:11024"))
	if err != nil {
		return err
	}
	defer nc.Close()
	msg := &nats.Msg{
		Subject: subject,
		Data:    data,
		Header:  nats.Header{"X-Origin": {origin}},
	}
	return nc.PublishMsg(msg)
}

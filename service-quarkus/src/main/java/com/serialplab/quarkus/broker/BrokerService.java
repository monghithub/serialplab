package com.serialplab.quarkus.broker;

import io.nats.client.Connection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.header.internals.RecordHeader;

import java.nio.charset.StandardCharsets;
import java.util.Properties;

@ApplicationScoped
public class BrokerService {

    @Inject
    Connection natsConnection;

    public void publish(String broker, String target, String protocol, byte[] data, String origin) throws Exception {
        String subject = "serialplab." + target + "." + protocol;
        switch (broker.toLowerCase()) {
            case "kafka" -> publishKafka(subject, data, origin);
            case "rabbitmq" -> publishRabbitDirect(subject, data, origin);
            case "nats" -> {
                io.nats.client.impl.Headers headers = new io.nats.client.impl.Headers();
                headers.put("X-Origin", origin);
                natsConnection.publish(subject, headers, data);
            }
            default -> throw new IllegalArgumentException("Unknown broker: " + broker);
        }
    }

    private void publishKafka(String topic, byte[] data, String origin) {
        var props = new Properties();
        props.put("bootstrap.servers", System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:11021"));
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
        try (var producer = new KafkaProducer<String, byte[]>(props)) {
            ProducerRecord<String, byte[]> record = new ProducerRecord<>(topic, data);
            record.headers().add(new RecordHeader("X-Origin", origin.getBytes(StandardCharsets.UTF_8)));
            producer.send(record).get();
        } catch (Exception e) {
            throw new RuntimeException("Kafka publish failed", e);
        }
    }

    private void publishRabbitDirect(String routingKey, byte[] data, String origin) throws Exception {
        var factory = new com.rabbitmq.client.ConnectionFactory();
        factory.setHost(System.getenv().getOrDefault("RABBITMQ_HOST", "localhost"));
        factory.setPort(Integer.parseInt(System.getenv().getOrDefault("RABBITMQ_PORT", "11022")));
        factory.setUsername("guest");
        factory.setPassword("guest");
        try (var conn = factory.newConnection(); var channel = conn.createChannel()) {
            var props = new com.rabbitmq.client.AMQP.BasicProperties.Builder()
                .headers(java.util.Map.of("X-Origin", origin))
                .build();
            channel.basicPublish("amq.topic", routingKey, props, data);
        }
    }
}

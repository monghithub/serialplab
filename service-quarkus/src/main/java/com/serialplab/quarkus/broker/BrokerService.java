package com.serialplab.quarkus.broker;

import io.nats.client.Connection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.util.Properties;

@ApplicationScoped
public class BrokerService {

    @Inject
    Connection natsConnection;

    public void publish(String broker, String target, String protocol, byte[] data) throws Exception {
        String subject = "serialplab." + target + "." + protocol;
        switch (broker.toLowerCase()) {
            case "kafka" -> publishKafka(subject, data);
            case "rabbitmq" -> publishRabbitDirect(subject, data);
            case "nats" -> natsConnection.publish(subject, data);
            default -> throw new IllegalArgumentException("Unknown broker: " + broker);
        }
    }

    private void publishKafka(String topic, byte[] data) {
        var props = new Properties();
        props.put("bootstrap.servers", "localhost:11021");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.ByteArraySerializer");
        try (var producer = new KafkaProducer<String, byte[]>(props)) {
            producer.send(new ProducerRecord<>(topic, data)).get();
        } catch (Exception e) {
            throw new RuntimeException("Kafka publish failed", e);
        }
    }

    private void publishRabbitDirect(String routingKey, byte[] data) throws Exception {
        var factory = new com.rabbitmq.client.ConnectionFactory();
        factory.setHost("localhost");
        factory.setPort(11022);
        factory.setUsername("guest");
        factory.setPassword("guest");
        try (var conn = factory.newConnection(); var channel = conn.createChannel()) {
            channel.basicPublish("", routingKey, null, data);
        }
    }
}
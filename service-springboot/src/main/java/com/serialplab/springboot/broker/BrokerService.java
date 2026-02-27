package com.serialplab.springboot.broker;

import io.nats.client.Connection;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class BrokerService {

    private final KafkaTemplate<String, byte[]> kafkaTemplate;
    private final AmqpTemplate amqpTemplate;
    private final Connection natsConnection;

    public BrokerService(KafkaTemplate<String, byte[]> kafkaTemplate,
                         AmqpTemplate amqpTemplate,
                         Connection natsConnection) {
        this.kafkaTemplate = kafkaTemplate;
        this.amqpTemplate = amqpTemplate;
        this.natsConnection = natsConnection;
    }

    public void publish(String broker, String target, String protocol, byte[] data) throws Exception {
        String subject = "serialplab." + target + "." + protocol;
        switch (broker.toLowerCase()) {
            case "kafka" -> kafkaTemplate.send(subject, data);
            case "rabbitmq" -> amqpTemplate.convertAndSend(subject, data);
            case "nats" -> natsConnection.publish(subject, data);
            default -> throw new IllegalArgumentException("Unknown broker: " + broker);
        }
    }
}
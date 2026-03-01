package com.serialplab.springboot.broker;

import io.nats.client.Connection;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.header.internals.RecordHeader;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;

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

    public void publish(String broker, String target, String protocol, byte[] data, String origin) throws Exception {
        String subject = "serialplab." + target + "." + protocol;
        switch (broker.toLowerCase()) {
            case "kafka" -> {
                ProducerRecord<String, byte[]> record = new ProducerRecord<>(subject, data);
                record.headers().add(new RecordHeader("X-Origin", origin.getBytes(StandardCharsets.UTF_8)));
                kafkaTemplate.send(record);
            }
            case "rabbitmq" -> {
                MessageProperties props = new MessageProperties();
                props.setHeader("X-Origin", origin);
                amqpTemplate.send(subject, new Message(data, props));
            }
            case "nats" -> {
                io.nats.client.impl.Headers headers = new io.nats.client.impl.Headers();
                headers.put("X-Origin", origin);
                natsConnection.publish(subject, headers, data);
            }
            default -> throw new IllegalArgumentException("Unknown broker: " + broker);
        }
    }
}

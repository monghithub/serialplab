package com.serialplab.springboot.broker;

import com.serialplab.springboot.serialization.SerializationService;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class BrokerConsumer {

    private static final Logger log = LoggerFactory.getLogger(BrokerConsumer.class);
    private final SerializationService serializationService;
    private final Connection natsConnection;

    public BrokerConsumer(SerializationService serializationService, Connection natsConnection) {
        this.serializationService = serializationService;
        this.natsConnection = natsConnection;
    }

    @PostConstruct
    public void initNatsSubscription() {
        try {
            Dispatcher dispatcher = natsConnection.createDispatcher(msg -> {
                String subject = msg.getSubject();
                String protocol = extractProtocol(subject);
                try {
                    Map<String, Object> user = serializationService.deserialize(protocol, msg.getData());
                    log.info("[NATS] Received on {}: {}", subject, user);
                } catch (Exception e) {
                    log.error("[NATS] Deserialization error on {}: {}", subject, e.getMessage());
                }
            });
            dispatcher.subscribe("serialplab.service-springboot.>");
            log.info("[NATS] Subscribed to serialplab.service-springboot.>");
        } catch (Exception e) {
            log.warn("[NATS] Subscription failed: {}", e.getMessage());
        }
    }

    @KafkaListener(topicPattern = "serialplab\\.service-springboot\\..*", groupId = "springboot-group")
    public void consumeKafka(byte[] data, org.apache.kafka.clients.consumer.ConsumerRecord<String, byte[]> record) {
        String topic = record.topic();
        String protocol = extractProtocol(topic);
        try {
            Map<String, Object> user = serializationService.deserialize(protocol, data);
            log.info("[Kafka] Received on {}: {}", topic, user);
        } catch (Exception e) {
            log.error("[Kafka] Deserialization error on {}: {}", topic, e.getMessage());
        }
    }

    @RabbitListener(queues = "#{@rabbitQueues}")
    public void consumeRabbit(byte[] data, org.springframework.amqp.core.Message message) {
        String routingKey = message.getMessageProperties().getReceivedRoutingKey();
        String protocol = extractProtocol(routingKey);
        try {
            Map<String, Object> user = serializationService.deserialize(protocol, data);
            log.info("[RabbitMQ] Received on {}: {}", routingKey, user);
        } catch (Exception e) {
            log.error("[RabbitMQ] Deserialization error on {}: {}", routingKey, e.getMessage());
        }
    }

    private String extractProtocol(String subject) {
        String[] parts = subject.split("\\.");
        return parts.length >= 3 ? parts[2] : "json";
    }
}
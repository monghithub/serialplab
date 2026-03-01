package com.serialplab.springboot.broker;

import com.serialplab.springboot.model.MessageLog;
import com.serialplab.springboot.repository.MessageLogRepository;
import com.serialplab.springboot.serialization.SerializationService;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import jakarta.annotation.PostConstruct;
import org.apache.kafka.common.header.Header;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.Map;

@Component
public class BrokerConsumer {

    private static final Logger log = LoggerFactory.getLogger(BrokerConsumer.class);
    private final SerializationService serializationService;
    private final Connection natsConnection;
    private final MessageLogRepository messageLogRepository;

    public BrokerConsumer(SerializationService serializationService, Connection natsConnection, MessageLogRepository messageLogRepository) {
        this.serializationService = serializationService;
        this.natsConnection = natsConnection;
        this.messageLogRepository = messageLogRepository;
    }

    @PostConstruct
    public void initNatsSubscription() {
        try {
            Dispatcher dispatcher = natsConnection.createDispatcher(msg -> {
                String subject = msg.getSubject();
                String protocol = extractProtocol(subject);
                try {
                    Map<String, Object> user = serializationService.deserialize(protocol, msg.getData());
                    String origin = "unknown";
                    if (msg.getHeaders() != null && msg.getHeaders().get("X-Origin") != null && !msg.getHeaders().get("X-Origin").isEmpty()) {
                        origin = msg.getHeaders().get("X-Origin").get(0);
                    }
                    log.info("[NATS] Received on {}: {} from {}", subject, user, origin);
                    saveReceived("nats", protocol, user, msg.getData(), origin);
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
            String origin = "unknown";
            Header h = record.headers().lastHeader("X-Origin");
            if (h != null) {
                origin = new String(h.value(), StandardCharsets.UTF_8);
            }
            log.info("[Kafka] Received on {}: {} from {}", topic, user, origin);
            saveReceived("kafka", protocol, user, data, origin);
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
            String origin = "unknown";
            Object headerVal = message.getMessageProperties().getHeader("X-Origin");
            if (headerVal != null) {
                origin = headerVal.toString();
            }
            log.info("[RabbitMQ] Received on {}: {} from {}", routingKey, user, origin);
            saveReceived("rabbitmq", protocol, user, data, origin);
        } catch (Exception e) {
            log.error("[RabbitMQ] Deserialization error on {}: {}", routingKey, e.getMessage());
        }
    }

    private void saveReceived(String broker, String protocol, Map<String, Object> user, byte[] rawPayload, String origin) {
        try {
            messageLogRepository.save(new MessageLog(
                "received", protocol, broker, "service-springboot", origin, rawPayload,
                (String) user.get("id"),
                (String) user.get("name"),
                (String) user.get("email"),
                ((Number) user.get("timestamp")).longValue()
            ));
        } catch (Exception e) {
            log.error("Failed to save received message: {}", e.getMessage());
        }
    }

    private String extractProtocol(String subject) {
        String[] parts = subject.split("\\.");
        return parts.length >= 3 ? parts[2] : "json";
    }
}

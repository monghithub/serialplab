package com.serialplab.quarkus.broker;

import com.serialplab.quarkus.serialization.SerializationService;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.jboss.logging.Logger;

import java.time.Duration;
import java.util.Map;
import java.util.Properties;
import java.util.regex.Pattern;

@ApplicationScoped
public class BrokerConsumer {

    private static final Logger log = Logger.getLogger(BrokerConsumer.class);

    @Inject
    SerializationService serializationService;

    @Inject
    Connection natsConnection;

    void onStart(@Observes StartupEvent ev) {
        startNatsConsumer();
        startKafkaConsumer();
        startRabbitConsumer();
    }

    private void startNatsConsumer() {
        try {
            Dispatcher dispatcher = natsConnection.createDispatcher(msg -> {
                String subject = msg.getSubject();
                String protocol = extractProtocol(subject);
                try {
                    Map<String, Object> user = serializationService.deserialize(protocol, msg.getData());
                    log.infof("[NATS] Received on %s: %s", subject, user);
                } catch (Exception e) {
                    log.errorf("[NATS] Error on %s: %s", subject, e.getMessage());
                }
            });
            dispatcher.subscribe("serialplab.service-quarkus.>");
            log.info("[NATS] Subscribed to serialplab.service-quarkus.>");
        } catch (Exception e) {
            log.warnf("[NATS] Subscription failed: %s", e.getMessage());
        }
    }

    private void startKafkaConsumer() {
        Thread.ofVirtual().start(() -> {
            Properties props = new Properties();
            props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:11021");
            props.put(ConsumerConfig.GROUP_ID_CONFIG, "quarkus-group");
            props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
            props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, ByteArrayDeserializer.class.getName());
            props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "latest");
            try (KafkaConsumer<String, byte[]> consumer = new KafkaConsumer<>(props)) {
                consumer.subscribe(Pattern.compile("serialplab\\.service-quarkus\\..*"));
                while (!Thread.currentThread().isInterrupted()) {
                    ConsumerRecords<String, byte[]> records = consumer.poll(Duration.ofMillis(1000));
                    records.forEach(record -> {
                        String protocol = extractProtocol(record.topic());
                        try {
                            Map<String, Object> user = serializationService.deserialize(protocol, record.value());
                            log.infof("[Kafka] Received on %s: %s", record.topic(), user);
                        } catch (Exception e) {
                            log.errorf("[Kafka] Error on %s: %s", record.topic(), e.getMessage());
                        }
                    });
                }
            }
        });
    }

    private void startRabbitConsumer() {
        Thread.ofVirtual().start(() -> {
            try {
                var factory = new com.rabbitmq.client.ConnectionFactory();
                factory.setHost("localhost");
                factory.setPort(11022);
                factory.setUsername("guest");
                factory.setPassword("guest");
                var conn = factory.newConnection();
                var channel = conn.createChannel();
                String queueName = "serialplab.service-quarkus.queue";
                channel.queueDeclare(queueName, true, false, false, null);
                String bindKey = "serialplab.service-quarkus.*";
                channel.queueBind(queueName, "amq.topic", bindKey);
                log.infof("[RabbitMQ] Consuming queue: %s", queueName);
                channel.basicConsume(queueName, true, (consumerTag, delivery) -> {
                    String routingKey = delivery.getEnvelope().getRoutingKey();
                    String protocol = extractProtocol(routingKey);
                    try {
                        var user = serializationService.deserialize(protocol, delivery.getBody());
                        log.infof("[RabbitMQ] Received on %s: %s", routingKey, user);
                    } catch (Exception e) {
                        log.errorf("[RabbitMQ] Error on %s: %s", routingKey, e.getMessage());
                    }
                }, consumerTag -> {});
            } catch (Exception e) {
                log.warnf("[RabbitMQ] Consumer failed: %s", e.getMessage());
            }
        });
    }

    private String extractProtocol(String subject) {
        String[] parts = subject.split("\\.");
        return parts.length >= 3 ? parts[2] : "json";
    }
}
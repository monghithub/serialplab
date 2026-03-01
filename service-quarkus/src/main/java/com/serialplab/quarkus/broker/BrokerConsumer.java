package com.serialplab.quarkus.broker;

import com.serialplab.quarkus.serialization.SerializationService;
import io.nats.client.Connection;
import io.nats.client.Dispatcher;
import io.quarkus.runtime.StartupEvent;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.event.Observes;
import jakarta.inject.Inject;
import javax.sql.DataSource;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.header.Header;
import org.apache.kafka.common.serialization.ByteArrayDeserializer;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.jboss.logging.Logger;

import java.nio.charset.StandardCharsets;
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

    @Inject
    DataSource dataSource;

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
                    String origin = "unknown";
                    if (msg.getHeaders() != null && msg.getHeaders().get("X-Origin") != null && !msg.getHeaders().get("X-Origin").isEmpty()) {
                        origin = msg.getHeaders().get("X-Origin").get(0);
                    }
                    log.infof("[NATS] Received on %s: %s from %s", subject, user, origin);
                    saveReceived("nats", protocol, user, msg.getData(), origin);
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
            props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, System.getenv().getOrDefault("KAFKA_BOOTSTRAP_SERVERS", "localhost:11021"));
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
                            String origin = "unknown";
                            Header h = record.headers().lastHeader("X-Origin");
                            if (h != null) {
                                origin = new String(h.value(), StandardCharsets.UTF_8);
                            }
                            log.infof("[Kafka] Received on %s: %s from %s", record.topic(), user, origin);
                            saveReceived("kafka", protocol, user, record.value(), origin);
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
                factory.setHost(System.getenv().getOrDefault("RABBITMQ_HOST", "localhost"));
                factory.setPort(Integer.parseInt(System.getenv().getOrDefault("RABBITMQ_PORT", "11022")));
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
                        String origin = "unknown";
                        if (delivery.getProperties().getHeaders() != null) {
                            Object val = delivery.getProperties().getHeaders().get("X-Origin");
                            if (val != null) origin = val.toString();
                        }
                        log.infof("[RabbitMQ] Received on %s: %s from %s", routingKey, user, origin);
                        saveReceived("rabbitmq", protocol, user, delivery.getBody(), origin);
                    } catch (Exception e) {
                        log.errorf("[RabbitMQ] Error on %s: %s", routingKey, e.getMessage());
                    }
                }, consumerTag -> {});
            } catch (Exception e) {
                log.warnf("[RabbitMQ] Consumer failed: %s", e.getMessage());
            }
        });
    }

    private void saveReceived(String broker, String protocol, Map<String, Object> user, byte[] rawPayload, String origin) {
        String sql = "INSERT INTO quarkus.message_log (id, direction, protocol, broker, targetservice, originservice, rawpayload, userid, username, useremail, usertimestamp, created_at) VALUES (nextval('quarkus.message_log_seq'),?,?,?,?,?,?,?,?,?,?,now())";
        try (var conn = dataSource.getConnection(); var ps = conn.prepareStatement(sql)) {
            ps.setString(1, "received");
            ps.setString(2, protocol);
            ps.setString(3, broker);
            ps.setString(4, "service-quarkus");
            ps.setString(5, origin);
            ps.setBytes(6, rawPayload);
            ps.setString(7, (String) user.get("id"));
            ps.setString(8, (String) user.get("name"));
            ps.setString(9, (String) user.get("email"));
            ps.setLong(10, ((Number) user.get("timestamp")).longValue());
            ps.executeUpdate();
        } catch (Exception e) {
            log.errorf("Failed to save received message: %s", e.getMessage());
        }
    }

    private String extractProtocol(String subject) {
        String[] parts = subject.split("\\.");
        return parts.length >= 3 ? parts[2] : "json";
    }
}

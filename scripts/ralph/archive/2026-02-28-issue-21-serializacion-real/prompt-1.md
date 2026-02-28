# Tarea: Consume en service-springboot + service-quarkus

## Issue: #22
## Subtarea: 1 de 2

## Objetivo

Añadir funcionalidad de consume/subscribe a los broker services de Spring Boot y Quarkus. Los servicios deben poder suscribirse a mensajes de los 3 brokers.

## Ficheros a crear

- `service-springboot/src/main/java/com/serialplab/springboot/broker/BrokerConsumer.java`
- `service-quarkus/src/main/java/com/serialplab/quarkus/broker/BrokerConsumer.java`

## Contexto

Topic pattern: `serialplab.{target}.{protocol}`. Cada servicio consume mensajes dirigidos a él.

### service-springboot/src/main/java/com/serialplab/springboot/broker/BrokerConsumer.java

```java
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
```

### service-quarkus/src/main/java/com/serialplab/quarkus/broker/BrokerConsumer.java

```java
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

    private String extractProtocol(String subject) {
        String[] parts = subject.split("\\.");
        return parts.length >= 3 ? parts[2] : "json";
    }
}
```

## Validación

```bash
test -f service-springboot/src/main/java/com/serialplab/springboot/broker/BrokerConsumer.java && test -f service-quarkus/src/main/java/com/serialplab/quarkus/broker/BrokerConsumer.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

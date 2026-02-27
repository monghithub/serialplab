# Tarea: Configuración brokers Kafka, RabbitMQ, NATS

## Issue: #3
## Subtarea: 3 de 4

## Objetivo

Crear las clases de configuración e integración con los 3 brokers: Kafka, RabbitMQ y NATS. Incluye un BrokerService que abstrae el envío/recepción.

## Ficheros a crear

- `service-springboot/src/main/java/com/serialplab/springboot/broker/BrokerService.java`
- `service-springboot/src/main/java/com/serialplab/springboot/broker/KafkaConfig.java`
- `service-springboot/src/main/java/com/serialplab/springboot/broker/RabbitConfig.java`
- `service-springboot/src/main/java/com/serialplab/springboot/broker/NatsConfig.java`

## Contexto

Cada broker publica/consume mensajes como `byte[]`. El topic/queue sigue el patrón: `serialplab.{target}.{protocol}`.

### BrokerService.java

```java
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
```

### KafkaConfig.java

```java
package com.serialplab.springboot.broker;

import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.common.serialization.ByteArraySerializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    @Bean
    public ProducerFactory<String, byte[]> producerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, ByteArraySerializer.class);
        return new DefaultKafkaProducerFactory<>(props);
    }

    @Bean
    public KafkaTemplate<String, byte[]> kafkaTemplate() {
        return new KafkaTemplate<>(producerFactory());
    }
}
```

### RabbitConfig.java

```java
package com.serialplab.springboot.broker;

import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    @Bean
    public AmqpTemplate amqpTemplate(ConnectionFactory connectionFactory) {
        return new RabbitTemplate(connectionFactory);
    }
}
```

### NatsConfig.java

```java
package com.serialplab.springboot.broker;

import io.nats.client.Connection;
import io.nats.client.Nats;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class NatsConfig {

    @Value("${nats.url}")
    private String natsUrl;

    @Bean
    public Connection natsConnection() throws IOException, InterruptedException {
        return Nats.connect(natsUrl);
    }
}
```

## Validación

```bash
test -f service-springboot/src/main/java/com/serialplab/springboot/broker/BrokerService.java && test -f service-springboot/src/main/java/com/serialplab/springboot/broker/KafkaConfig.java && test -f service-springboot/src/main/java/com/serialplab/springboot/broker/RabbitConfig.java && test -f service-springboot/src/main/java/com/serialplab/springboot/broker/NatsConfig.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

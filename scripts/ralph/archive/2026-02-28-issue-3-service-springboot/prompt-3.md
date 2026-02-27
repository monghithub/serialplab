# Tarea: Configuración brokers Kafka, RabbitMQ, NATS

## Issue: #4
## Subtarea: 3 de 4

## Objetivo

Crear el servicio de broker que abstrae el envío a Kafka, RabbitMQ y NATS. Quarkus no usa Spring Kafka/AMQP — usamos clientes directos.

## Ficheros a crear

- `service-quarkus/src/main/java/com/serialplab/quarkus/broker/BrokerService.java`
- `service-quarkus/src/main/java/com/serialplab/quarkus/broker/NatsProducer.java`

## Contexto

Para Kafka usamos el cliente Java nativo (no quarkus-messaging para tener control sobre byte[]). Para RabbitMQ usamos AMQP client directo. Para NATS usamos jnats. El topic/queue sigue el patrón: `serialplab.{target}.{protocol}`.

### BrokerService.java

```java
package com.serialplab.quarkus.broker;

import io.nats.client.Connection;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

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
        var props = new java.util.Properties();
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
```

### NatsProducer.java

CDI producer para crear la conexión NATS como bean inyectable.

```java
package com.serialplab.quarkus.broker;

import io.nats.client.Connection;
import io.nats.client.Nats;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class NatsProducer {

    @ConfigProperty(name = "nats.url", defaultValue = "nats://localhost:11024")
    String natsUrl;

    @Produces
    @ApplicationScoped
    public Connection natsConnection() throws Exception {
        return Nats.connect(natsUrl);
    }
}
```

**NOTA:** Necesitamos añadir las dependencias de Kafka client y RabbitMQ client al pom.xml. Añadir estas dependencias extras:

Añade al pom.xml existente (en la sección dependencies, ANTES del cierre `</dependencies>`):

```xml
        <!-- Kafka client -->
        <dependency>
            <groupId>org.apache.kafka</groupId>
            <artifactId>kafka-clients</artifactId>
        </dependency>
        <!-- RabbitMQ client -->
        <dependency>
            <groupId>com.rabbitmq</groupId>
            <artifactId>amqp-client</artifactId>
            <version>5.22.0</version>
        </dependency>
```

## Validación

```bash
test -f service-quarkus/src/main/java/com/serialplab/quarkus/broker/BrokerService.java && test -f service-quarkus/src/main/java/com/serialplab/quarkus/broker/NatsProducer.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

# Tarea: Proyecto Maven + application.yml + HealthController

## Issue: #3
## Subtarea: 1 de 4

## Objetivo

Crear el esqueleto del proyecto Spring Boot 3 con Maven: pom.xml, application.yml, clase principal y health endpoint.

## Ficheros a crear

- `service-springboot/pom.xml`
- `service-springboot/src/main/resources/application.yml`
- `service-springboot/src/main/java/com/serialplab/springboot/Application.java`
- `service-springboot/src/main/java/com/serialplab/springboot/controller/HealthController.java`

## Contexto

Base package: `com.serialplab.springboot`. Puerto: 11001. PostgreSQL en localhost:11010, schema `springboot`.

### pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.2</version>
    </parent>
    <groupId>com.serialplab</groupId>
    <artifactId>service-springboot</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>service-springboot</name>
    <properties>
        <java.version>21</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <!-- Kafka -->
        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>
        <!-- RabbitMQ -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
        </dependency>
        <!-- NATS -->
        <dependency>
            <groupId>io.nats</groupId>
            <artifactId>jnats</artifactId>
            <version>2.20.5</version>
        </dependency>
        <!-- Protobuf -->
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java</artifactId>
            <version>4.29.3</version>
        </dependency>
        <!-- Avro -->
        <dependency>
            <groupId>org.apache.avro</groupId>
            <artifactId>avro</artifactId>
            <version>1.12.0</version>
        </dependency>
        <!-- Thrift -->
        <dependency>
            <groupId>org.apache.thrift</groupId>
            <artifactId>libthrift</artifactId>
            <version>0.21.0</version>
        </dependency>
        <!-- MessagePack -->
        <dependency>
            <groupId>org.msgpack</groupId>
            <artifactId>msgpack-core</artifactId>
            <version>0.9.8</version>
        </dependency>
        <!-- FlatBuffers -->
        <dependency>
            <groupId>com.google.flatbuffers</groupId>
            <artifactId>flatbuffers-java</artifactId>
            <version>24.12.23</version>
        </dependency>
        <!-- CBOR (Jackson) -->
        <dependency>
            <groupId>com.fasterxml.jackson.dataformat</groupId>
            <artifactId>jackson-dataformat-cbor</artifactId>
        </dependency>
        <!-- JSON Schema Validator -->
        <dependency>
            <groupId>com.networknt</groupId>
            <artifactId>json-schema-validator</artifactId>
            <version>1.5.4</version>
        </dependency>
        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

### application.yml

```yaml
server:
  port: 11001

spring:
  application:
    name: service-springboot
  datasource:
    url: jdbc:postgresql://localhost:11010/serialplab?currentSchema=springboot
    username: serialplab
    password: serialplab
  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        default_schema: springboot
    open-in-view: false
  kafka:
    bootstrap-servers: localhost:11021
    consumer:
      group-id: springboot-group
      auto-offset-reset: earliest
  rabbitmq:
    host: localhost
    port: 11022
    username: guest
    password: guest

nats:
  url: nats://localhost:11024
```

### Application.java

```java
package com.serialplab.springboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### HealthController.java

```java
package com.serialplab.springboot.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class HealthController {
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }
}
```

## Validación

```bash
test -f service-springboot/pom.xml && test -f service-springboot/src/main/resources/application.yml && test -f service-springboot/src/main/java/com/serialplab/springboot/Application.java && test -f service-springboot/src/main/java/com/serialplab/springboot/controller/HealthController.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push` de todos los ficheros generados/modificados.

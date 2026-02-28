# Tarea: REST controllers publish y messages + Dockerfile

## Issue: #3
## Subtarea: 4 de 4

## Objetivo

Crear los 2 controllers REST (publish y messages) y un Dockerfile multi-stage para el servicio.

## Ficheros a crear

- `service-springboot/src/main/java/com/serialplab/springboot/controller/PublishController.java`
- `service-springboot/src/main/java/com/serialplab/springboot/controller/MessagesController.java`
- `service-springboot/Dockerfile`

## Contexto

### PublishController.java

Endpoint POST `/publish/{target}/{protocol}/{broker}`. Recibe un JSON User en el body, lo serializa con el protocolo indicado y lo publica al broker.

```java
package com.serialplab.springboot.controller;

import com.serialplab.springboot.broker.BrokerService;
import com.serialplab.springboot.model.MessageLog;
import com.serialplab.springboot.repository.MessageLogRepository;
import com.serialplab.springboot.serialization.SerializationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/publish")
public class PublishController {

    private final SerializationService serializationService;
    private final BrokerService brokerService;
    private final MessageLogRepository messageLogRepository;

    public PublishController(SerializationService serializationService,
                             BrokerService brokerService,
                             MessageLogRepository messageLogRepository) {
        this.serializationService = serializationService;
        this.brokerService = brokerService;
        this.messageLogRepository = messageLogRepository;
    }

    @PostMapping("/{target}/{protocol}/{broker}")
    public ResponseEntity<Map<String, String>> publish(
            @PathVariable String target,
            @PathVariable String protocol,
            @PathVariable String broker,
            @RequestBody Map<String, Object> user) {
        try {
            byte[] data = serializationService.serialize(protocol, user);
            brokerService.publish(broker, target, protocol, data);

            messageLogRepository.save(new MessageLog(
                "sent", protocol, broker, target,
                (String) user.get("id"),
                (String) user.get("name"),
                (String) user.get("email"),
                ((Number) user.get("timestamp")).longValue()
            ));

            return ResponseEntity.ok(Map.of(
                "status", "published",
                "target", target,
                "protocol", protocol,
                "broker", broker,
                "bytes", String.valueOf(data.length)
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }
}
```

### MessagesController.java

```java
package com.serialplab.springboot.controller;

import com.serialplab.springboot.model.MessageLog;
import com.serialplab.springboot.repository.MessageLogRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class MessagesController {

    private final MessageLogRepository messageLogRepository;

    public MessagesController(MessageLogRepository messageLogRepository) {
        this.messageLogRepository = messageLogRepository;
    }

    @GetMapping("/messages")
    public List<MessageLog> messages() {
        return messageLogRepository.findAllByOrderByCreatedAtDesc();
    }
}
```

### Dockerfile (multi-stage)

**IMPORTANTE:** NO incluir `version:` en ningún fichero YAML. El Dockerfile usa multi-stage build con Maven.

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 11001
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Validación

```bash
test -f service-springboot/src/main/java/com/serialplab/springboot/controller/PublishController.java && test -f service-springboot/src/main/java/com/serialplab/springboot/controller/MessagesController.java && test -f service-springboot/Dockerfile && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

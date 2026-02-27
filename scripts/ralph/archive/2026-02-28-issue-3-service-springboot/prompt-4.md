# Tarea: REST resources publish y messages + Dockerfile

## Issue: #4
## Subtarea: 4 de 4

## Objetivo

Crear los 2 JAX-RS resources (publish y messages) y un Dockerfile multi-stage para el servicio Quarkus.

## Ficheros a crear

- `service-quarkus/src/main/java/com/serialplab/quarkus/PublishResource.java`
- `service-quarkus/src/main/java/com/serialplab/quarkus/MessagesResource.java`
- `service-quarkus/Dockerfile`

## Contexto

Quarkus usa JAX-RS annotations (`@Path`, `@POST`, `@GET`, etc.), NO Spring MVC.

### PublishResource.java

```java
package com.serialplab.quarkus;

import com.serialplab.quarkus.broker.BrokerService;
import com.serialplab.quarkus.model.MessageLog;
import com.serialplab.quarkus.serialization.SerializationService;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/publish")
public class PublishResource {

    @Inject
    SerializationService serializationService;

    @Inject
    BrokerService brokerService;

    @POST
    @Path("/{target}/{protocol}/{broker}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Response publish(@PathParam("target") String target,
                            @PathParam("protocol") String protocol,
                            @PathParam("broker") String broker,
                            Map<String, Object> user) {
        try {
            byte[] data = serializationService.serialize(protocol, user);
            brokerService.publish(broker, target, protocol, data);

            var log = new MessageLog(
                "sent", protocol, broker, target,
                (String) user.get("id"),
                (String) user.get("name"),
                (String) user.get("email"),
                ((Number) user.get("timestamp")).longValue()
            );
            log.persist();

            return Response.ok(Map.of(
                "status", "published",
                "target", target,
                "protocol", protocol,
                "broker", broker,
                "bytes", String.valueOf(data.length)
            )).build();
        } catch (Exception e) {
            return Response.serverError()
                .entity(Map.of("error", e.getMessage()))
                .build();
        }
    }
}
```

### MessagesResource.java

```java
package com.serialplab.quarkus;

import com.serialplab.quarkus.model.MessageLog;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

@Path("/messages")
public class MessagesResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<MessageLog> messages() {
        return MessageLog.listAll();
    }
}
```

### Dockerfile (multi-stage, JVM mode)

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/quarkus-app /app
EXPOSE 11002
ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]
```

## Validación

```bash
test -f service-quarkus/src/main/java/com/serialplab/quarkus/PublishResource.java && test -f service-quarkus/src/main/java/com/serialplab/quarkus/MessagesResource.java && test -f service-quarkus/Dockerfile && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

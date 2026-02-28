# Tarea: Entidad JPA + repositorio + SerializationService

## Issue: #4
## Subtarea: 2 de 4

## Objetivo

Crear el modelo de dominio JPA con Panache, y el servicio de serialización para los 7 protocolos.

## Ficheros a crear

- `service-quarkus/src/main/java/com/serialplab/quarkus/model/MessageLog.java`
- `service-quarkus/src/main/java/com/serialplab/quarkus/serialization/SerializationService.java`

## Contexto

Quarkus usa Hibernate ORM con Panache (PanacheEntity para repositorios simplificados). MessageLog registra cada mensaje enviado/recibido.

### MessageLog.java

```java
package com.serialplab.quarkus.model;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "message_log", schema = "quarkus")
public class MessageLog extends PanacheEntity {

    public String direction;
    public String protocol;
    public String broker;
    public String targetService;
    public String userId;
    public String userName;
    public String userEmail;
    public long userTimestamp;

    @Column(name = "created_at")
    public Instant createdAt = Instant.now();

    public MessageLog() {}

    public MessageLog(String direction, String protocol, String broker,
                      String targetService, String userId, String userName,
                      String userEmail, long userTimestamp) {
        this.direction = direction;
        this.protocol = protocol;
        this.broker = broker;
        this.targetService = targetService;
        this.userId = userId;
        this.userName = userName;
        this.userEmail = userEmail;
        this.userTimestamp = userTimestamp;
        this.createdAt = Instant.now();
    }
}
```

### SerializationService.java

Misma lógica que service-springboot pero como CDI bean (`@ApplicationScoped`).

```java
package com.serialplab.quarkus.serialization;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import jakarta.enterprise.context.ApplicationScoped;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessagePack;
import org.msgpack.core.MessageUnpacker;

import java.util.HashMap;
import java.util.Map;

@ApplicationScoped
public class SerializationService {

    private final ObjectMapper jsonMapper = new ObjectMapper();
    private final ObjectMapper cborMapper = new ObjectMapper(new CBORFactory());

    public byte[] serialize(String protocol, Map<String, Object> user) throws Exception {
        return switch (protocol.toLowerCase()) {
            case "json", "json-schema" -> jsonMapper.writeValueAsBytes(user);
            case "cbor" -> cborMapper.writeValueAsBytes(user);
            case "msgpack", "messagepack" -> serializeMsgpack(user);
            case "protobuf", "avro", "thrift", "flatbuffers" -> jsonMapper.writeValueAsBytes(user);
            default -> throw new IllegalArgumentException("Unknown protocol: " + protocol);
        };
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> deserialize(String protocol, byte[] data) throws Exception {
        return switch (protocol.toLowerCase()) {
            case "json", "json-schema" -> jsonMapper.readValue(data, Map.class);
            case "cbor" -> cborMapper.readValue(data, Map.class);
            case "msgpack", "messagepack" -> deserializeMsgpack(data);
            case "protobuf", "avro", "thrift", "flatbuffers" -> jsonMapper.readValue(data, Map.class);
            default -> throw new IllegalArgumentException("Unknown protocol: " + protocol);
        };
    }

    private byte[] serializeMsgpack(Map<String, Object> user) throws Exception {
        try (MessageBufferPacker packer = MessagePack.newDefaultBufferPacker()) {
            packer.packMapHeader(4);
            packer.packString("id"); packer.packString((String) user.get("id"));
            packer.packString("name"); packer.packString((String) user.get("name"));
            packer.packString("email"); packer.packString((String) user.get("email"));
            packer.packString("timestamp"); packer.packLong(((Number) user.get("timestamp")).longValue());
            return packer.toByteArray();
        }
    }

    private Map<String, Object> deserializeMsgpack(byte[] data) throws Exception {
        try (MessageUnpacker unpacker = MessagePack.newDefaultUnpacker(data)) {
            int size = unpacker.unpackMapHeader();
            Map<String, Object> result = new HashMap<>();
            for (int i = 0; i < size; i++) {
                String key = unpacker.unpackString();
                if ("timestamp".equals(key)) {
                    result.put(key, unpacker.unpackLong());
                } else {
                    result.put(key, unpacker.unpackString());
                }
            }
            return result;
        }
    }
}
```

## Validación

```bash
test -f service-quarkus/src/main/java/com/serialplab/quarkus/model/MessageLog.java && test -f service-quarkus/src/main/java/com/serialplab/quarkus/serialization/SerializationService.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

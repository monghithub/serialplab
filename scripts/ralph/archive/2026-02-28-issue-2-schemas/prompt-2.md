# Tarea: Entidades JPA + repositorio + SerializationService

## Issue: #3
## Subtarea: 2 de 4

## Objetivo

Crear el modelo de dominio JPA (MessageLog), su repositorio, y el servicio de serialización con soporte para los 7 protocolos.

## Ficheros a crear

- `service-springboot/src/main/java/com/serialplab/springboot/model/MessageLog.java`
- `service-springboot/src/main/java/com/serialplab/springboot/repository/MessageLogRepository.java`
- `service-springboot/src/main/java/com/serialplab/springboot/serialization/SerializationService.java`

## Contexto

El modelo User NO es una entidad JPA — es solo un DTO que se serializa/deserializa. MessageLog registra cada mensaje enviado/recibido.

### MessageLog.java

```java
package com.serialplab.springboot.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "message_log", schema = "springboot")
public class MessageLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String direction; // "sent" or "received"
    private String protocol;
    private String broker;
    private String targetService;
    private String userId;
    private String userName;
    private String userEmail;
    private long userTimestamp;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

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

    public Long getId() { return id; }
    public String getDirection() { return direction; }
    public String getProtocol() { return protocol; }
    public String getBroker() { return broker; }
    public String getTargetService() { return targetService; }
    public String getUserId() { return userId; }
    public String getUserName() { return userName; }
    public String getUserEmail() { return userEmail; }
    public long getUserTimestamp() { return userTimestamp; }
    public Instant getCreatedAt() { return createdAt; }
}
```

### MessageLogRepository.java

```java
package com.serialplab.springboot.repository;

import com.serialplab.springboot.model.MessageLog;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MessageLogRepository extends JpaRepository<MessageLog, Long> {
    List<MessageLog> findAllByOrderByCreatedAtDesc();
}
```

### SerializationService.java

Servicio que serializa/deserializa un User (Map con id, name, email, timestamp) en 7 protocolos. Protobuf, Avro, Thrift y FlatBuffers usan JSON como placeholder (se reemplazará con code-gen más adelante).

```java
package com.serialplab.springboot.serialization;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessagePack;
import org.msgpack.core.MessageUnpacker;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
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
test -f service-springboot/src/main/java/com/serialplab/springboot/model/MessageLog.java && test -f service-springboot/src/main/java/com/serialplab/springboot/repository/MessageLogRepository.java && test -f service-springboot/src/main/java/com/serialplab/springboot/serialization/SerializationService.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

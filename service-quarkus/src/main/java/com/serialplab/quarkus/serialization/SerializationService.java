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
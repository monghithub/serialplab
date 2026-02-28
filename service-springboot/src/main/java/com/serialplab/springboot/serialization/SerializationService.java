package com.serialplab.springboot.serialization;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.cbor.CBORFactory;
import com.google.flatbuffers.FlatBufferBuilder;
import com.google.protobuf.CodedInputStream;
import com.google.protobuf.CodedOutputStream;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.*;
import org.apache.thrift.TException;
import org.apache.thrift.protocol.TCompactProtocol;
import org.apache.thrift.protocol.TField;
import org.apache.thrift.protocol.TStruct;
import org.apache.thrift.protocol.TType;
import org.apache.thrift.transport.TIOStreamTransport;
import org.apache.thrift.transport.TMemoryInputTransport;
import org.msgpack.core.MessageBufferPacker;
import org.msgpack.core.MessagePack;
import org.msgpack.core.MessageUnpacker;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

@Service
public class SerializationService {

    private final ObjectMapper jsonMapper = new ObjectMapper();
    private final ObjectMapper cborMapper = new ObjectMapper(new CBORFactory());
    private final Schema avroSchema;

    public SerializationService() {
        try {
            avroSchema = new Schema.Parser().parse(
                getClass().getClassLoader().getResourceAsStream("avro/message.avsc")
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to load Avro schema", e);
        }
    }

    public byte[] serialize(String protocol, Map<String, Object> user) throws Exception {
        return switch (protocol.toLowerCase()) {
            case "json", "json-schema" -> jsonMapper.writeValueAsBytes(user);
            case "cbor" -> cborMapper.writeValueAsBytes(user);
            case "msgpack", "messagepack" -> serializeMsgpack(user);
            case "protobuf" -> serializeProtobuf(user);
            case "avro" -> serializeAvro(user);
            case "thrift" -> serializeThrift(user);
            case "flatbuffers" -> serializeFlatBuffers(user);
            default -> throw new IllegalArgumentException("Unknown protocol: " + protocol);
        };
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> deserialize(String protocol, byte[] data) throws Exception {
        return switch (protocol.toLowerCase()) {
            case "json", "json-schema" -> jsonMapper.readValue(data, Map.class);
            case "cbor" -> cborMapper.readValue(data, Map.class);
            case "msgpack", "messagepack" -> deserializeMsgpack(data);
            case "protobuf" -> deserializeProtobuf(data);
            case "avro" -> deserializeAvro(data);
            case "thrift" -> deserializeThrift(data);
            case "flatbuffers" -> deserializeFlatBuffers(data);
            default -> throw new IllegalArgumentException("Unknown protocol: " + protocol);
        };
    }

    // --- MessagePack ---
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
                if ("timestamp".equals(key)) result.put(key, unpacker.unpackLong());
                else result.put(key, unpacker.unpackString());
            }
            return result;
        }
    }

    // --- Protobuf (manual wire format) ---
    private byte[] serializeProtobuf(Map<String, Object> user) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        CodedOutputStream cos = CodedOutputStream.newInstance(baos);
        cos.writeString(1, (String) user.get("id"));
        cos.writeString(2, (String) user.get("name"));
        cos.writeString(3, (String) user.get("email"));
        cos.writeInt64(4, ((Number) user.get("timestamp")).longValue());
        cos.flush();
        return baos.toByteArray();
    }

    private Map<String, Object> deserializeProtobuf(byte[] data) throws Exception {
        CodedInputStream cis = CodedInputStream.newInstance(data);
        Map<String, Object> result = new HashMap<>();
        while (!cis.isAtEnd()) {
            int tag = cis.readTag();
            int fieldNumber = tag >>> 3;
            switch (fieldNumber) {
                case 1 -> result.put("id", cis.readString());
                case 2 -> result.put("name", cis.readString());
                case 3 -> result.put("email", cis.readString());
                case 4 -> result.put("timestamp", cis.readInt64());
                default -> cis.skipField(tag);
            }
        }
        return result;
    }

    // --- Avro (GenericRecord) ---
    private byte[] serializeAvro(Map<String, Object> user) throws Exception {
        GenericRecord record = new GenericData.Record(avroSchema);
        record.put("id", user.get("id"));
        record.put("name", user.get("name"));
        record.put("email", user.get("email"));
        record.put("timestamp", ((Number) user.get("timestamp")).longValue());
        GenericDatumWriter<GenericRecord> writer = new GenericDatumWriter<>(avroSchema);
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(baos, null);
        writer.write(record, encoder);
        encoder.flush();
        return baos.toByteArray();
    }

    private Map<String, Object> deserializeAvro(byte[] data) throws Exception {
        GenericDatumReader<GenericRecord> reader = new GenericDatumReader<>(avroSchema);
        BinaryDecoder decoder = DecoderFactory.get().binaryDecoder(data, null);
        GenericRecord record = reader.read(null, decoder);
        Map<String, Object> result = new HashMap<>();
        result.put("id", record.get("id").toString());
        result.put("name", record.get("name").toString());
        result.put("email", record.get("email").toString());
        result.put("timestamp", (Long) record.get("timestamp"));
        return result;
    }

    // --- Thrift (TCompactProtocol manual) ---
    private byte[] serializeThrift(Map<String, Object> user) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        TCompactProtocol proto = new TCompactProtocol(new TIOStreamTransport(baos));
        proto.writeStructBegin(new TStruct("User"));
        proto.writeFieldBegin(new TField("id", TType.STRING, (short) 1));
        proto.writeString((String) user.get("id"));
        proto.writeFieldEnd();
        proto.writeFieldBegin(new TField("name", TType.STRING, (short) 2));
        proto.writeString((String) user.get("name"));
        proto.writeFieldEnd();
        proto.writeFieldBegin(new TField("email", TType.STRING, (short) 3));
        proto.writeString((String) user.get("email"));
        proto.writeFieldEnd();
        proto.writeFieldBegin(new TField("timestamp", TType.I64, (short) 4));
        proto.writeI64(((Number) user.get("timestamp")).longValue());
        proto.writeFieldEnd();
        proto.writeFieldStop();
        proto.writeStructEnd();
        return baos.toByteArray();
    }

    private Map<String, Object> deserializeThrift(byte[] data) throws Exception {
        TCompactProtocol proto = new TCompactProtocol(new TMemoryInputTransport(data));
        Map<String, Object> result = new HashMap<>();
        proto.readStructBegin();
        while (true) {
            TField field = proto.readFieldBegin();
            if (field.type == TType.STOP) break;
            switch (field.id) {
                case 1 -> result.put("id", proto.readString());
                case 2 -> result.put("name", proto.readString());
                case 3 -> result.put("email", proto.readString());
                case 4 -> result.put("timestamp", proto.readI64());
                default -> org.apache.thrift.protocol.TProtocolUtil.skip(proto, field.type);
            }
            proto.readFieldEnd();
        }
        proto.readStructEnd();
        return result;
    }

    // --- FlatBuffers (manual) ---
    private byte[] serializeFlatBuffers(Map<String, Object> user) {
        FlatBufferBuilder builder = new FlatBufferBuilder(256);
        int idOff = builder.createString((String) user.get("id"));
        int nameOff = builder.createString((String) user.get("name"));
        int emailOff = builder.createString((String) user.get("email"));
        long timestamp = ((Number) user.get("timestamp")).longValue();
        // Table: 4 fields (vtable size=12, table size varies)
        builder.startTable(4);
        builder.addOffset(0, idOff, 0);
        builder.addOffset(1, nameOff, 0);
        builder.addOffset(2, emailOff, 0);
        builder.addLong(3, timestamp, 0);
        int root = builder.endTable();
        builder.finish(root);
        ByteBuffer buf = builder.dataBuffer();
        byte[] result = new byte[buf.remaining()];
        buf.get(result);
        return result;
    }

    private Map<String, Object> deserializeFlatBuffers(byte[] data) {
        ByteBuffer buf = ByteBuffer.wrap(data);
        int rootTable = buf.getInt(buf.position()) + buf.position();
        int vtableOffset = rootTable - buf.getInt(rootTable);
        Map<String, Object> result = new HashMap<>();
        // Read vtable to find field offsets
        int vtableSize = buf.getShort(vtableOffset) & 0xFFFF;
        if (vtableSize > 4) {
            int idField = buf.getShort(vtableOffset + 4) & 0xFFFF;
            if (idField != 0) result.put("id", readFbString(buf, rootTable + idField));
        }
        if (vtableSize > 6) {
            int nameField = buf.getShort(vtableOffset + 6) & 0xFFFF;
            if (nameField != 0) result.put("name", readFbString(buf, rootTable + nameField));
        }
        if (vtableSize > 8) {
            int emailField = buf.getShort(vtableOffset + 8) & 0xFFFF;
            if (emailField != 0) result.put("email", readFbString(buf, rootTable + emailField));
        }
        if (vtableSize > 10) {
            int tsField = buf.getShort(vtableOffset + 10) & 0xFFFF;
            if (tsField != 0) result.put("timestamp", buf.getLong(rootTable + tsField));
        }
        return result;
    }

    private String readFbString(ByteBuffer buf, int offset) {
        int strOffset = offset + buf.getInt(offset);
        int len = buf.getInt(strOffset);
        byte[] bytes = new byte[len];
        buf.position(strOffset + 4);
        buf.get(bytes);
        return new String(bytes, StandardCharsets.UTF_8);
    }
}
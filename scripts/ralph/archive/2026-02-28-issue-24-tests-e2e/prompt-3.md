# Tarea: Serialización real en service-go

## Issue: #21
## Subtarea: 3 de 4

## Objetivo

Reemplazar los placeholders de serialización en service-go con implementaciones reales.

## Ficheros a modificar

- `service-go/internal/serialization/serialization.go`

## Contexto

Model User: `ID string`, `Name string`, `Email string`, `Timestamp int64`.

Usa las librerías de go.mod: protobuf (google.golang.org/protobuf), goavro (github.com/linkedin/goavro/v2), thrift (github.com/apache/thrift), flatbuffers (github.com/google/flatbuffers).

Para Protobuf y Thrift usa encoding manual del wire format (sin código generado).
Para Avro usa goavro con codec de schema.
Para FlatBuffers usa flatbuffers.Builder.

### Contenido COMPLETO de serialization.go

```go
package serialization

import (
	"encoding/binary"
	"encoding/json"
	"fmt"
	"math"

	"github.com/fxamacker/cbor/v2"
	flatbuffers "github.com/google/flatbuffers/go"
	"github.com/linkedin/goavro/v2"
	"github.com/vmihailenco/msgpack/v5"
	"serialplab/service-go/internal/model"
)

var avroCodec *goavro.Codec

func init() {
	var err error
	avroCodec, err = goavro.NewCodec(`{
		"type": "record",
		"name": "User",
		"namespace": "com.serialplab.avro",
		"fields": [
			{"name": "id", "type": "string"},
			{"name": "name", "type": "string"},
			{"name": "email", "type": "string"},
			{"name": "timestamp", "type": "long"}
		]
	}`)
	if err != nil {
		panic("failed to create Avro codec: " + err.Error())
	}
}

func Serialize(protocol string, user model.User) ([]byte, error) {
	switch protocol {
	case "json", "json-schema":
		return json.Marshal(user)
	case "cbor":
		return cbor.Marshal(user)
	case "msgpack", "messagepack":
		return msgpack.Marshal(user)
	case "protobuf":
		return serializeProtobuf(user)
	case "avro":
		return serializeAvro(user)
	case "thrift":
		return serializeThrift(user)
	case "flatbuffers":
		return serializeFlatBuffers(user)
	default:
		return nil, fmt.Errorf("unknown protocol: %s", protocol)
	}
}

func Deserialize(protocol string, data []byte) (model.User, error) {
	var user model.User
	var err error
	switch protocol {
	case "json", "json-schema":
		err = json.Unmarshal(data, &user)
	case "cbor":
		err = cbor.Unmarshal(data, &user)
	case "msgpack", "messagepack":
		err = msgpack.Unmarshal(data, &user)
	case "protobuf":
		return deserializeProtobuf(data)
	case "avro":
		return deserializeAvro(data)
	case "thrift":
		return deserializeThrift(data)
	case "flatbuffers":
		return deserializeFlatBuffers(data)
	default:
		return user, fmt.Errorf("unknown protocol: %s", protocol)
	}
	return user, err
}

// --- Protobuf (manual wire format) ---
func serializeProtobuf(user model.User) ([]byte, error) {
	var buf []byte
	// field 1: id (string, wire type 2)
	buf = appendProtoString(buf, 1, user.ID)
	// field 2: name
	buf = appendProtoString(buf, 2, user.Name)
	// field 3: email
	buf = appendProtoString(buf, 3, user.Email)
	// field 4: timestamp (int64, wire type 0)
	buf = appendProtoVarint(buf, 4, user.Timestamp)
	return buf, nil
}

func appendProtoString(buf []byte, field int, s string) []byte {
	tag := uint64(field<<3 | 2) // wire type 2 = length-delimited
	buf = binary.AppendUvarint(buf, tag)
	buf = binary.AppendUvarint(buf, uint64(len(s)))
	buf = append(buf, s...)
	return buf
}

func appendProtoVarint(buf []byte, field int, val int64) []byte {
	tag := uint64(field<<3 | 0) // wire type 0 = varint
	buf = binary.AppendUvarint(buf, tag)
	buf = binary.AppendUvarint(buf, uint64(val))
	return buf
}

func deserializeProtobuf(data []byte) (model.User, error) {
	var user model.User
	i := 0
	for i < len(data) {
		tag, n := binary.Uvarint(data[i:])
		i += n
		fieldNum := int(tag >> 3)
		wireType := int(tag & 0x7)
		switch fieldNum {
		case 1, 2, 3:
			if wireType != 2 {
				return user, fmt.Errorf("unexpected wire type for field %d", fieldNum)
			}
			length, n := binary.Uvarint(data[i:])
			i += n
			s := string(data[i : i+int(length)])
			i += int(length)
			switch fieldNum {
			case 1:
				user.ID = s
			case 2:
				user.Name = s
			case 3:
				user.Email = s
			}
		case 4:
			val, n := binary.Uvarint(data[i:])
			i += n
			user.Timestamp = int64(val)
		default:
			return user, fmt.Errorf("unknown field: %d", fieldNum)
		}
	}
	return user, nil
}

// --- Avro (goavro) ---
func serializeAvro(user model.User) ([]byte, error) {
	native := map[string]interface{}{
		"id":        user.ID,
		"name":      user.Name,
		"email":     user.Email,
		"timestamp": user.Timestamp,
	}
	return avroCodec.BinaryFromNative(nil, native)
}

func deserializeAvro(data []byte) (model.User, error) {
	native, _, err := avroCodec.NativeFromBinary(data)
	if err != nil {
		return model.User{}, err
	}
	m := native.(map[string]interface{})
	return model.User{
		ID:        m["id"].(string),
		Name:      m["name"].(string),
		Email:     m["email"].(string),
		Timestamp: m["timestamp"].(int64),
	}, nil
}

// --- Thrift (TCompactProtocol manual) ---
func serializeThrift(user model.User) ([]byte, error) {
	var buf []byte
	prevID := 0
	// field 1: id (type STRING=11)
	buf = appendThriftField(buf, 11, 1, prevID)
	prevID = 1
	buf = appendThriftString(buf, user.ID)
	// field 2: name
	buf = appendThriftField(buf, 11, 2, prevID)
	prevID = 2
	buf = appendThriftString(buf, user.Name)
	// field 3: email
	buf = appendThriftField(buf, 11, 3, prevID)
	prevID = 3
	buf = appendThriftString(buf, user.Email)
	// field 4: timestamp (type I64=6)
	buf = appendThriftField(buf, 6, 4, prevID)
	buf = appendThriftI64(buf, user.Timestamp)
	// STOP
	buf = append(buf, 0)
	return buf, nil
}

func appendThriftField(buf []byte, thriftType, fieldID, prevID int) []byte {
	delta := fieldID - prevID
	if delta > 0 && delta <= 15 {
		buf = append(buf, byte(delta<<4|thriftType))
	} else {
		buf = append(buf, byte(thriftType))
		buf = binary.AppendUvarint(buf, uint64((fieldID<<1)^(fieldID>>31)))
	}
	return buf
}

func appendThriftString(buf []byte, s string) []byte {
	buf = binary.AppendUvarint(buf, uint64(len(s)))
	buf = append(buf, s...)
	return buf
}

func appendThriftI64(buf []byte, val int64) []byte {
	zigzag := uint64((val << 1) ^ (val >> 63))
	buf = binary.AppendUvarint(buf, zigzag)
	return buf
}

func deserializeThrift(data []byte) (model.User, error) {
	var user model.User
	i := 0
	prevID := 0
	for i < len(data) {
		if data[i] == 0 {
			break // STOP
		}
		b := data[i]
		i++
		delta := int(b >> 4)
		thriftType := int(b & 0x0f)
		fieldID := prevID + delta
		if delta == 0 {
			zigzag, n := binary.Uvarint(data[i:])
			i += n
			fieldID = int(int32(zigzag>>1) ^ -int32(zigzag&1))
			_ = thriftType
		}
		prevID = fieldID
		switch fieldID {
		case 1, 2, 3: // STRING
			length, n := binary.Uvarint(data[i:])
			i += n
			s := string(data[i : i+int(length)])
			i += int(length)
			switch fieldID {
			case 1:
				user.ID = s
			case 2:
				user.Name = s
			case 3:
				user.Email = s
			}
		case 4: // I64
			zigzag, n := binary.Uvarint(data[i:])
			i += n
			user.Timestamp = int64(zigzag>>1) ^ -int64(zigzag&1)
		}
	}
	return user, nil
}

// --- FlatBuffers (manual) ---
func serializeFlatBuffers(user model.User) ([]byte, error) {
	builder := flatbuffers.NewBuilder(256)
	idOff := builder.CreateString(user.ID)
	nameOff := builder.CreateString(user.Name)
	emailOff := builder.CreateString(user.Email)
	builder.StartObject(4)
	builder.PrependUOffsetTSlot(0, idOff, 0)
	builder.PrependUOffsetTSlot(1, nameOff, 0)
	builder.PrependUOffsetTSlot(2, emailOff, 0)
	builder.PrependInt64Slot(3, user.Timestamp, 0)
	root := builder.EndObject()
	builder.Finish(root)
	return builder.FinishedBytes(), nil
}

func deserializeFlatBuffers(data []byte) (model.User, error) {
	buf := data
	rootOffset := int(binary.LittleEndian.Uint32(buf[0:4]))
	tablePos := rootOffset
	vtableOffset := tablePos - int(int32(binary.LittleEndian.Uint32(buf[tablePos:tablePos+4])))
	vtableSize := int(binary.LittleEndian.Uint16(buf[vtableOffset : vtableOffset+2]))
	var user model.User
	if vtableSize > 4 {
		off := int(binary.LittleEndian.Uint16(buf[vtableOffset+4 : vtableOffset+6]))
		if off != 0 {
			user.ID = readFbString(buf, tablePos+off)
		}
	}
	if vtableSize > 6 {
		off := int(binary.LittleEndian.Uint16(buf[vtableOffset+6 : vtableOffset+8]))
		if off != 0 {
			user.Name = readFbString(buf, tablePos+off)
		}
	}
	if vtableSize > 8 {
		off := int(binary.LittleEndian.Uint16(buf[vtableOffset+8 : vtableOffset+10]))
		if off != 0 {
			user.Email = readFbString(buf, tablePos+off)
		}
	}
	if vtableSize > 10 {
		off := int(binary.LittleEndian.Uint16(buf[vtableOffset+10 : vtableOffset+12]))
		if off != 0 {
			user.Timestamp = int64(binary.LittleEndian.Uint64(buf[tablePos+off : tablePos+off+8]))
		}
	}
	return user, nil
}

func readFbString(buf []byte, offset int) string {
	strOffset := offset + int(binary.LittleEndian.Uint32(buf[offset:offset+4]))
	length := int(binary.LittleEndian.Uint32(buf[strOffset : strOffset+4]))
	return string(buf[strOffset+4 : strOffset+4+length])
}

// suppress unused import
var _ = math.MaxFloat64
```

## Validación

```bash
grep -q "serializeProtobuf" service-go/internal/serialization/serialization.go && grep -q "serializeAvro" service-go/internal/serialization/serialization.go && grep -q "goavro" service-go/internal/serialization/serialization.go && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

package serialization

import (
	"encoding/json"
	"fmt"

	"github.com/fxamacker/cbor/v2"
	"github.com/vmihailenco/msgpack/v5"
	"serialplab/service-go/internal/model"
)

func Serialize(protocol string, user model.User) ([]byte, error) {
	switch protocol {
	case "json", "json-schema":
		return json.Marshal(user)
	case "cbor":
		return cbor.Marshal(user)
	case "msgpack", "messagepack":
		return msgpack.Marshal(user)
	case "protobuf", "avro", "thrift", "flatbuffers":
		return json.Marshal(user) // placeholder
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
	case "protobuf", "avro", "thrift", "flatbuffers":
		err = json.Unmarshal(data, &user) // placeholder
	default:
		return user, fmt.Errorf("unknown protocol: %s", protocol)
	}
	return user, err
}
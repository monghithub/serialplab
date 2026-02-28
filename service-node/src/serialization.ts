import { encode as msgpackEncode, decode as msgpackDecode } from '@msgpack/msgpack';
import { encode as cborEncode, decode as cborDecode } from 'cbor-x';

export interface User {
  id: string;
  name: string;
  email: string;
  timestamp: number;
}

export function serialize(protocol: string, user: User): Buffer {
  switch (protocol.toLowerCase()) {
    case 'json':
    case 'json-schema':
      return Buffer.from(JSON.stringify(user));
    case 'cbor':
      return Buffer.from(cborEncode(user));
    case 'msgpack':
    case 'messagepack':
      return Buffer.from(msgpackEncode(user));
    case 'protobuf':
    case 'avro':
    case 'thrift':
    case 'flatbuffers':
      return Buffer.from(JSON.stringify(user)); // placeholder
    default:
      throw new Error(`Unknown protocol: ${protocol}`);
  }
}

export function deserialize(protocol: string, data: Buffer): User {
  switch (protocol.toLowerCase()) {
    case 'json':
    case 'json-schema':
      return JSON.parse(data.toString());
    case 'cbor':
      return cborDecode(data) as User;
    case 'msgpack':
    case 'messagepack':
      return msgpackDecode(data) as User;
    case 'protobuf':
    case 'avro':
    case 'thrift':
    case 'flatbuffers':
      return JSON.parse(data.toString()); // placeholder
    default:
      throw new Error(`Unknown protocol: ${protocol}`);
  }
}
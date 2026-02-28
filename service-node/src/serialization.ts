import { encode as msgpackEncode, decode as msgpackDecode } from '@msgpack/msgpack';
import { encode as cborEncode, decode as cborDecode } from 'cbor-x';
import * as protobuf from 'protobufjs';
import * as avro from 'avsc';
import * as flatbuffers from 'flatbuffers';

export interface User {
  id: string;
  name: string;
  email: string;
  timestamp: number;
}

// --- Protobuf schema (dynamic) ---
const UserProto = protobuf.Type.fromJSON('User', {
  fields: {
    id: { type: 'string', id: 1 },
    name: { type: 'string', id: 2 },
    email: { type: 'string', id: 3 },
    timestamp: { type: 'int64', id: 4 },
  },
});

// --- Avro schema ---
const UserAvro = avro.Type.forSchema({
  type: 'record',
  name: 'User',
  fields: [
    { name: 'id', type: 'string' },
    { name: 'name', type: 'string' },
    { name: 'email', type: 'string' },
    { name: 'timestamp', type: 'long' },
  ],
});

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
      return Buffer.from(UserProto.encode(UserProto.create(user)).finish());
    case 'avro':
      return UserAvro.toBuffer(user);
    case 'thrift':
      return serializeThrift(user);
    case 'flatbuffers':
      return serializeFlatBuffers(user);
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
    case 'protobuf': {
      const msg = UserProto.decode(data);
      const obj = UserProto.toObject(msg, { longs: Number });
      return obj as User;
    }
    case 'avro':
      return UserAvro.fromBuffer(data) as User;
    case 'thrift':
      return deserializeThrift(data);
    case 'flatbuffers':
      return deserializeFlatBuffers(data);
    default:
      throw new Error(`Unknown protocol: ${protocol}`);
  }
}

// --- Thrift Compact Protocol (manual) ---
function serializeThrift(user: User): Buffer {
  const parts: number[] = [];
  let prevId = 0;

  // field 1: id (type STRING=8 in compact)
  writeThriftField(parts, 8, 1, prevId);
  prevId = 1;
  writeThriftString(parts, user.id);

  // field 2: name
  writeThriftField(parts, 8, 2, prevId);
  prevId = 2;
  writeThriftString(parts, user.name);

  // field 3: email
  writeThriftField(parts, 8, 3, prevId);
  prevId = 3;
  writeThriftString(parts, user.email);

  // field 4: timestamp (type I64=6 in compact)
  writeThriftField(parts, 6, 4, prevId);
  writeThriftI64(parts, user.timestamp);

  // STOP
  parts.push(0);

  return Buffer.from(parts);
}

function writeThriftField(parts: number[], type: number, id: number, prevId: number): void {
  const delta = id - prevId;
  if (delta > 0 && delta <= 15) {
    parts.push((delta << 4) | type);
  } else {
    parts.push(type);
    writeVarint(parts, (id << 1) ^ (id >> 31));
  }
}

function writeThriftString(parts: number[], s: string): void {
  const bytes = Buffer.from(s, 'utf-8');
  writeVarint(parts, bytes.length);
  for (const b of bytes) parts.push(b);
}

function writeThriftI64(parts: number[], val: number): void {
  const zigzag = (val << 1) ^ (val >> 63);
  writeVarint(parts, zigzag >= 0 ? zigzag : zigzag + 2 ** 64);
}

function writeVarint(parts: number[], val: number): void {
  let v = val;
  while (v > 127) {
    parts.push((v & 0x7f) | 0x80);
    v = Math.floor(v / 128);
  }
  parts.push(v & 0x7f);
}

function deserializeThrift(data: Buffer): User {
  let i = 0;
  let prevId = 0;
  const user: any = {};

  while (i < data.length) {
    if (data[i] === 0) break;
    const b = data[i++];
    const delta = (b >> 4) & 0x0f;
    const type = b & 0x0f;
    let fieldId: number;
    if (delta !== 0) {
      fieldId = prevId + delta;
    } else {
      const [zigzag, n] = readVarint(data, i);
      i += n;
      fieldId = (zigzag >>> 1) ^ -(zigzag & 1);
    }
    prevId = fieldId;

    if (fieldId >= 1 && fieldId <= 3) {
      const [len, n] = readVarint(data, i);
      i += n;
      const s = data.subarray(i, i + len).toString('utf-8');
      i += len;
      if (fieldId === 1) user.id = s;
      else if (fieldId === 2) user.name = s;
      else user.email = s;
    } else if (fieldId === 4) {
      const [zigzag, n] = readVarint(data, i);
      i += n;
      user.timestamp = (zigzag >>> 1) ^ -(zigzag & 1);
    }
  }
  return user as User;
}

function readVarint(buf: Buffer, offset: number): [number, number] {
  let result = 0;
  let shift = 0;
  let i = offset;
  while (i < buf.length) {
    const b = buf[i++];
    result |= (b & 0x7f) << shift;
    if ((b & 0x80) === 0) break;
    shift += 7;
  }
  return [result, i - offset];
}

// --- FlatBuffers (manual, compatible with Go builder format) ---
function serializeFlatBuffers(user: User): Buffer {
  const builder = new flatbuffers.Builder(256);
  const idOff = builder.createString(user.id);
  const nameOff = builder.createString(user.name);
  const emailOff = builder.createString(user.email);
  builder.startObject(4);
  builder.addFieldOffset(0, idOff, 0);
  builder.addFieldOffset(1, nameOff, 0);
  builder.addFieldOffset(2, emailOff, 0);
  builder.addFieldInt64(3, BigInt(user.timestamp), BigInt(0));
  const root = builder.endObject();
  builder.finish(root);
  return Buffer.from(builder.asUint8Array());
}

function deserializeFlatBuffers(data: Buffer): User {
  const buf = new flatbuffers.ByteBuffer(new Uint8Array(data));
  const rootOffset = buf.readInt32(0);
  const tablePos = rootOffset;
  const vtableOffset = tablePos - buf.readInt32(tablePos);
  const vtableSize = buf.readInt16(vtableOffset);

  let id = '';
  let name = '';
  let email = '';
  let timestamp = 0;

  if (vtableSize > 4) {
    const off = buf.readInt16(vtableOffset + 4);
    if (off !== 0) id = readFbString(buf, tablePos + off);
  }
  if (vtableSize > 6) {
    const off = buf.readInt16(vtableOffset + 6);
    if (off !== 0) name = readFbString(buf, tablePos + off);
  }
  if (vtableSize > 8) {
    const off = buf.readInt16(vtableOffset + 8);
    if (off !== 0) email = readFbString(buf, tablePos + off);
  }
  if (vtableSize > 10) {
    const off = buf.readInt16(vtableOffset + 10);
    if (off !== 0) timestamp = Number(buf.readInt64(tablePos + off));
  }

  return { id, name, email, timestamp };
}

function readFbString(buf: flatbuffers.ByteBuffer, offset: number): string {
  const strOffset = offset + buf.readInt32(offset);
  const len = buf.readInt32(strOffset);
  const bytes = buf.bytes().subarray(strOffset + 4, strOffset + 4 + len);
  return Buffer.from(bytes).toString('utf-8');
}
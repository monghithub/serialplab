# Tarea: Serialización real en service-node

## Issue: #21
## Subtarea: 4 de 4

## Objetivo

Reemplazar los placeholders de serialización en service-node con implementaciones reales usando las librerías npm.

## Ficheros a modificar

- `service-node/src/serialization.ts`

## Contexto

User: `{ id: string, name: string, email: string, timestamp: number }`.

Librerías: protobufjs, avsc, thrift (manual compact protocol), flatbuffers.

Para Protobuf usa protobufjs con schema dinámico (Type.fromJSON).
Para Avro usa avsc con Type.forSchema.
Para Thrift usa encoding manual del compact protocol.
Para FlatBuffers usa flatbuffers Builder.

### Contenido COMPLETO de serialization.ts

```typescript
import { encode as msgpackEncode, decode as msgpackDecode } from '@msgpack/msgpack';
import { encode as cborEncode, decode as cborDecode } from 'cbor-x';
import * as protobuf from 'protobufjs';
import * as avro from 'avsc';

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

// --- FlatBuffers (manual) ---
function serializeFlatBuffers(user: User): Buffer {
  // Simple implementation using manual buffer construction
  const idBuf = Buffer.from(user.id, 'utf-8');
  const nameBuf = Buffer.from(user.name, 'utf-8');
  const emailBuf = Buffer.from(user.email, 'utf-8');

  // Use JSON as a pragmatic FlatBuffers placeholder until flatc generates proper accessors
  // Real FlatBuffers requires generated code for proper zero-copy access
  const payload = JSON.stringify({ ...user, _fmt: 'flatbuffers' });
  return Buffer.from(payload);
}

function deserializeFlatBuffers(data: Buffer): User {
  const obj = JSON.parse(data.toString());
  delete obj._fmt;
  return obj as User;
}
```

## Validación

```bash
grep -q "protobufjs\|protobuf" service-node/src/serialization.ts && grep -q "avsc\|avro" service-node/src/serialization.ts && grep -q "serializeThrift" service-node/src/serialization.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

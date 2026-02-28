#!/usr/bin/env bash
# Genera código fuente desde los schemas compartidos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMAS_DIR="${PROJECT_ROOT}/schemas"

echo "=== Code Generation from Schemas ==="
echo ""

# --- Protobuf ---
echo "1/4 Protobuf (protoc)..."
if command -v protoc &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  protoc --java_out="${PROJECT_ROOT}/service-springboot/src/main/java" \
    --proto_path="${SCHEMAS_DIR}/protobuf" \
    "${SCHEMAS_DIR}/protobuf/message.proto"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  if command -v protoc-gen-go &>/dev/null; then
    mkdir -p "${PROJECT_ROOT}/service-go/internal/proto"
    protoc --go_out="${PROJECT_ROOT}/service-go/internal/proto" \
      --go_opt=paths=source_relative \
      --proto_path="${SCHEMAS_DIR}/protobuf" \
      "${SCHEMAS_DIR}/protobuf/message.proto"
  fi
  # Node/TS
  if command -v npx &>/dev/null; then
    mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
    npx pbjs -t static-module -w es6 -o "${PROJECT_ROOT}/service-node/src/generated/message.js" \
      "${SCHEMAS_DIR}/protobuf/message.proto" 2>/dev/null || true
    npx pbts -o "${PROJECT_ROOT}/service-node/src/generated/message.d.ts" \
      "${PROJECT_ROOT}/service-node/src/generated/message.js" 2>/dev/null || true
  fi
  echo "  OK"
else
  echo "  SKIP: protoc not found"
fi

# --- Avro ---
echo "2/4 Avro..."
echo "  Java: handled by avro-maven-plugin in pom.xml"
echo "  Go/Node: use dynamic schema loading (no codegen needed)"

# --- Thrift ---
echo "3/4 Thrift..."
if command -v thrift &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  thrift --gen java -out "${PROJECT_ROOT}/service-springboot/src/main/java" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  mkdir -p "${PROJECT_ROOT}/service-go/internal/thriftgen"
  thrift --gen go -out "${PROJECT_ROOT}/service-go/internal/thriftgen" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  # Node
  mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
  thrift --gen js:node -out "${PROJECT_ROOT}/service-node/src/generated" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  echo "  OK"
else
  echo "  SKIP: thrift not found"
fi

# --- FlatBuffers ---
echo "4/4 FlatBuffers (flatc)..."
if command -v flatc &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  flatc --java -o "${PROJECT_ROOT}/service-springboot/src/main/java" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  mkdir -p "${PROJECT_ROOT}/service-go/internal/flatgen"
  flatc --go -o "${PROJECT_ROOT}/service-go/internal/flatgen" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  # Node/TS
  mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
  flatc --ts -o "${PROJECT_ROOT}/service-node/src/generated" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  echo "  OK"
else
  echo "  SKIP: flatc not found"
fi

echo ""
echo "=== Code generation complete ==="
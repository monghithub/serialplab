#!/usr/bin/env bash
# Registra schemas en Apicurio Registry via API REST v3
set -euo pipefail

REGISTRY_URL="${REGISTRY_URL:-http://localhost:11011}"
GROUP="serialplab"
API_BASE="${REGISTRY_URL}/apis/registry/v3/groups/${GROUP}/artifacts"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Registering schemas in Apicurio Registry ==="
echo "Registry: ${REGISTRY_URL}"
echo "Group: ${GROUP}"
echo ""

# Register Avro schema
echo "1/3 Registering message-avro (AVRO)..."
curl -sf -X POST "$API_BASE" \
  -H "Content-Type: application/json" \
  -H "X-Registry-ArtifactId: message-avro" \
  -H "X-Registry-ArtifactType: AVRO" \
  -d @"${PROJECT_ROOT}/schemas/avro/message.avsc" \
  && echo "  OK" || echo "  WARN: may already exist"

# Register Protobuf schema
echo "2/3 Registering message-protobuf (PROTOBUF)..."
curl -sf -X POST "$API_BASE" \
  -H "Content-Type: application/x-protobuf" \
  -H "X-Registry-ArtifactId: message-protobuf" \
  -H "X-Registry-ArtifactType: PROTOBUF" \
  --data-binary @"${PROJECT_ROOT}/schemas/protobuf/message.proto" \
  && echo "  OK" || echo "  WARN: may already exist"

# Register JSON Schema
echo "3/3 Registering message-json (JSON)..."
curl -sf -X POST "$API_BASE" \
  -H "Content-Type: application/json" \
  -H "X-Registry-ArtifactId: message-json" \
  -H "X-Registry-ArtifactType: JSON" \
  -d @"${PROJECT_ROOT}/schemas/jsonschema/message.schema.json" \
  && echo "  OK" || echo "  WARN: may already exist"

echo ""
echo "=== Schema registration complete ==="

# Verify
echo ""
echo "Verifying registered artifacts..."
curl -sf "${API_BASE}" | python3 -m json.tool 2>/dev/null || curl -sf "${API_BASE}"
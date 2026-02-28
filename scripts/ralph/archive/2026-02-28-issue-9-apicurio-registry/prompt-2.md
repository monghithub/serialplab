# Tarea: Scripts de registro de schemas y health check

## Issue: #9
## Subtarea: 2 de 2

## Objetivo

Crear scripts bash para registrar los schemas (Avro, Protobuf, JSON Schema) en Apicurio Registry y para verificar el estado del registry.

## Ficheros a crear

- `scripts/apicurio/register-schemas.sh`
- `scripts/apicurio/wait-for-registry.sh`

## Contexto

Apicurio Registry expone la API REST v3 en `http://localhost:11011`. Los schemas se registran como artifacts en el grupo `serialplab`.

### scripts/apicurio/wait-for-registry.sh

```bash
#!/usr/bin/env bash
# Espera a que Apicurio Registry esté listo
set -euo pipefail

REGISTRY_URL="${REGISTRY_URL:-http://localhost:11011}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"

echo "Waiting for Apicurio Registry at ${REGISTRY_URL}..."

for i in $(seq 1 "$MAX_RETRIES"); do
  if curl -sf "${REGISTRY_URL}/health/ready" > /dev/null 2>&1; then
    echo "Apicurio Registry is ready!"
    exit 0
  fi
  echo "  Attempt $i/$MAX_RETRIES - not ready yet, retrying in ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

echo "ERROR: Apicurio Registry not ready after $MAX_RETRIES attempts"
exit 1
```

### scripts/apicurio/register-schemas.sh

```bash
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
```

## Validación

```bash
test -f scripts/apicurio/register-schemas.sh && test -f scripts/apicurio/wait-for-registry.sh && test -x scripts/apicurio/register-schemas.sh && test -x scripts/apicurio/wait-for-registry.sh && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.
- **Permisos:** Los scripts deben tener permisos de ejecución (`chmod +x`).

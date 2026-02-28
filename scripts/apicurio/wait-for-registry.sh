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
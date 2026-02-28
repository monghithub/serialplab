#!/usr/bin/env bash
# Test E2E: 84 combinaciones (4 servicios × 7 protocolos × 3 brokers)
set -euo pipefail

SERVICES=("service-springboot:11001" "service-quarkus:11002" "service-go:11003" "service-node:11004")
PROTOCOLS=("protobuf" "avro" "thrift" "messagepack" "flatbuffers" "cbor" "json-schema")
BROKERS=("kafka" "rabbitmq" "nats")

RESULTS_DIR="$(cd "$(dirname "$0")" && pwd)/../../test-results"
mkdir -p "$RESULTS_DIR"
RESULTS_FILE="$RESULTS_DIR/e2e-matrix-$(date +%Y%m%d-%H%M%S).csv"
SUMMARY_FILE="$RESULTS_DIR/e2e-summary-$(date +%Y%m%d-%H%M%S).md"

echo "service,target,broker,protocol,status,response_code,duration_ms" > "$RESULTS_FILE"

TOTAL=0
PASS=0
FAIL=0

USER_JSON='{"id":"550e8400-e29b-41d4-a716-446655440000","name":"Test User","email":"test@serialplab.example.com","timestamp":1709100000000}'

echo "=== serialplab E2E Test Matrix ==="
echo "Services: ${#SERVICES[@]}"
echo "Protocols: ${#PROTOCOLS[@]}"
echo "Brokers: ${#BROKERS[@]}"
echo "Total combinations: $((${#SERVICES[@]} * ${#SERVICES[@]} * ${#PROTOCOLS[@]} * ${#BROKERS[@]}))"
echo ""

for SOURCE in "${SERVICES[@]}"; do
  SRC_NAME="${SOURCE%%:*}"
  SRC_PORT="${SOURCE##*:}"

  for TARGET in "${SERVICES[@]}"; do
    TGT_NAME="${TARGET%%:*}"

    for BROKER in "${BROKERS[@]}"; do
      for PROTOCOL in "${PROTOCOLS[@]}"; do
        TOTAL=$((TOTAL + 1))

        START_MS=$(date +%s%N | cut -b1-13)
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
          -X POST "http://localhost:${SRC_PORT}/publish/${TGT_NAME}/${PROTOCOL}/${BROKER}" \
          -H "Content-Type: application/json" \
          -d "$USER_JSON" \
          --connect-timeout 5 --max-time 10 2>/dev/null || echo "000")
        END_MS=$(date +%s%N | cut -b1-13)
        DURATION=$((END_MS - START_MS))

        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
          STATUS="PASS"
          PASS=$((PASS + 1))
          ICON="✅"
        else
          STATUS="FAIL"
          FAIL=$((FAIL + 1))
          ICON="❌"
        fi

        echo "${ICON} ${SRC_NAME} → ${TGT_NAME} [${BROKER}/${PROTOCOL}] HTTP=${HTTP_CODE} ${DURATION}ms"
        echo "${SRC_NAME},${TGT_NAME},${BROKER},${PROTOCOL},${STATUS},${HTTP_CODE},${DURATION}" >> "$RESULTS_FILE"
      done
    done
  done
done

echo ""
echo "=== RESULTS ==="
echo "Total: ${TOTAL} | Pass: ${PASS} | Fail: ${FAIL}"
echo "Results: ${RESULTS_FILE}"

# Generate summary markdown
cat > "$SUMMARY_FILE" <<MDEOF
# E2E Test Results — $(date '+%Y-%m-%d %H:%M:%S')

## Summary

| Metric | Value |
|--------|-------|
| Total | ${TOTAL} |
| Pass | ${PASS} |
| Fail | ${FAIL} |
| Rate | $(( TOTAL > 0 ? PASS * 100 / TOTAL : 0 ))% |

## Matrix (Source → Target × Protocol × Broker)

See CSV: \`$(basename "$RESULTS_FILE")\`
MDEOF

echo "Summary: ${SUMMARY_FILE}"
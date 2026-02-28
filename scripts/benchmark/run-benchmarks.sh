#!/usr/bin/env bash
# Benchmark de serialización: mide payload size y latencia por protocolo × servicio × broker
set -euo pipefail

SERVICES=("service-springboot:11001" "service-quarkus:11002" "service-go:11003" "service-node:11004")
PROTOCOLS=("protobuf" "avro" "thrift" "messagepack" "flatbuffers" "cbor" "json-schema")
BROKERS=("kafka" "rabbitmq" "nats")
ITERATIONS="${ITERATIONS:-10}"

RESULTS_DIR="$(cd "$(dirname "$0")" && pwd)/../../benchmark-results"
mkdir -p "$RESULTS_DIR"
RESULTS_FILE="$RESULTS_DIR/benchmark-$(date +%Y%m%d-%H%M%S).csv"

echo "service,broker,protocol,iteration,http_code,response_time_ms" > "$RESULTS_FILE"

USER_JSON='{"id":"550e8400-e29b-41d4-a716-446655440000","name":"Benchmark User","email":"bench@serialplab.example.com","timestamp":1709100000000}'

echo "=== serialplab Serialization Benchmark ==="
echo "Iterations per combination: ${ITERATIONS}"
echo "Services: ${#SERVICES[@]}"
echo "Protocols: ${#PROTOCOLS[@]}"
echo "Brokers: ${#BROKERS[@]}"
echo ""

for SOURCE in "${SERVICES[@]}"; do
  SRC_NAME="${SOURCE%%:*}"
  SRC_PORT="${SOURCE##*:}"

  for BROKER in "${BROKERS[@]}"; do
    for PROTOCOL in "${PROTOCOLS[@]}"; do
      TOTAL_TIME=0
      SUCCESS=0

      for i in $(seq 1 "$ITERATIONS"); do
        PAYLOAD="{\"broker\":\"${BROKER}\",\"protocol\":\"${PROTOCOL}\",\"target\":\"${SRC_NAME}\",\"user\":${USER_JSON}}"

        RESULT=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" \
          -X POST "http://localhost:${SRC_PORT}/publish" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          --connect-timeout 5 --max-time 10 2>/dev/null || echo "000,0")

        HTTP_CODE="${RESULT%%,*}"
        TIME_SECS="${RESULT##*,}"
        TIME_MS=$(echo "$TIME_SECS * 1000" | bc 2>/dev/null || echo "0")

        echo "${SRC_NAME},${BROKER},${PROTOCOL},${i},${HTTP_CODE},${TIME_MS}" >> "$RESULTS_FILE"

        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
          SUCCESS=$((SUCCESS + 1))
          TOTAL_TIME=$(echo "$TOTAL_TIME + $TIME_MS" | bc 2>/dev/null || echo "0")
        fi
      done

      if [ "$SUCCESS" -gt 0 ]; then
        AVG_TIME=$(echo "scale=2; $TOTAL_TIME / $SUCCESS" | bc 2>/dev/null || echo "N/A")
        echo "✅ ${SRC_NAME} [${BROKER}/${PROTOCOL}]: ${SUCCESS}/${ITERATIONS} ok, avg=${AVG_TIME}ms"
      else
        echo "❌ ${SRC_NAME} [${BROKER}/${PROTOCOL}]: 0/${ITERATIONS} ok"
      fi
    done
  done
done

echo ""
echo "=== Benchmark complete ==="
echo "Results: ${RESULTS_FILE}"
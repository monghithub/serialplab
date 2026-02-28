# Tarea: Script de benchmarks y endpoint de métricas

## Issue: #25
## Subtarea: 1 de 1

## Objetivo

Crear un script de benchmarks que mide el rendimiento de serialización para cada protocolo y un script que recoge métricas de todos los servicios.

## Ficheros a crear

- `scripts/benchmark/run-benchmarks.sh`
- `scripts/benchmark/collect-metrics.sh`

## Contexto

Cada servicio expone `POST /publish` y debe poder medir tiempos de serialización internamente. El script hace N peticiones por combinación y calcula estadísticas.

### scripts/benchmark/run-benchmarks.sh

```bash
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
```

### scripts/benchmark/collect-metrics.sh

```bash
#!/usr/bin/env bash
# Recoge métricas de los servicios y genera informe comparativo
set -euo pipefail

RESULTS_DIR="$(cd "$(dirname "$0")" && pwd)/../../benchmark-results"
REPORT_FILE="$RESULTS_DIR/report-$(date +%Y%m%d-%H%M%S).md"

# Find latest benchmark CSV
LATEST_CSV=$(ls -t "$RESULTS_DIR"/benchmark-*.csv 2>/dev/null | head -1)

if [ -z "$LATEST_CSV" ]; then
  echo "No benchmark results found. Run run-benchmarks.sh first."
  exit 1
fi

echo "Generating report from: $(basename "$LATEST_CSV")"

cat > "$REPORT_FILE" <<EOF
# Serialization Benchmark Report — $(date '+%Y-%m-%d %H:%M:%S')

## Source Data
- File: \`$(basename "$LATEST_CSV")\`

## Average Response Time by Protocol (ms)

| Protocol | springboot | quarkus | go | node |
|----------|-----------|---------|-----|------|
EOF

PROTOCOLS=("protobuf" "avro" "thrift" "messagepack" "flatbuffers" "cbor" "json-schema")
SERVICES=("service-springboot" "service-quarkus" "service-go" "service-node")

for PROTOCOL in "${PROTOCOLS[@]}"; do
  ROW="| ${PROTOCOL} |"
  for SVC in "${SERVICES[@]}"; do
    AVG=$(awk -F',' -v svc="$SVC" -v proto="$PROTOCOL" \
      '$1==svc && $3==proto && $4!="iteration" && $5~/^2[0-9][0-9]$/ {sum+=$6; n++} END {if(n>0) printf "%.1f", sum/n; else print "N/A"}' \
      "$LATEST_CSV" 2>/dev/null || echo "N/A")
    ROW="${ROW} ${AVG} |"
  done
  echo "$ROW" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" <<EOF

## Average Response Time by Broker (ms)

| Broker | springboot | quarkus | go | node |
|--------|-----------|---------|-----|------|
EOF

BROKERS=("kafka" "rabbitmq" "nats")
for BROKER in "${BROKERS[@]}"; do
  ROW="| ${BROKER} |"
  for SVC in "${SERVICES[@]}"; do
    AVG=$(awk -F',' -v svc="$SVC" -v broker="$BROKER" \
      '$1==svc && $2==broker && $4!="iteration" && $5~/^2[0-9][0-9]$/ {sum+=$6; n++} END {if(n>0) printf "%.1f", sum/n; else print "N/A"}' \
      "$LATEST_CSV" 2>/dev/null || echo "N/A")
    ROW="${ROW} ${AVG} |"
  done
  echo "$ROW" >> "$REPORT_FILE"
done

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "*Generated by serialplab benchmark suite*" >> "$REPORT_FILE"

echo "Report generated: ${REPORT_FILE}"
cat "$REPORT_FILE"
```

## Validación

```bash
test -f scripts/benchmark/run-benchmarks.sh && test -f scripts/benchmark/collect-metrics.sh && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

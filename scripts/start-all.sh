#!/usr/bin/env bash
# Levanta todo el sistema serialplab: infra → servicios → schemas → test E2E
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[serialplab]${NC} $1"; }
ok()   { echo -e "${GREEN}[✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✘]${NC} $1"; }

# --- Parsear argumentos ---
RUN_E2E=false
SKIP_BUILD=false
STOP_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --e2e)       RUN_E2E=true ;;
    --no-build)  SKIP_BUILD=true ;;
    --stop)      STOP_ONLY=true ;;
    --help|-h)
      echo "Uso: $0 [opciones]"
      echo ""
      echo "Opciones:"
      echo "  --e2e        Ejecutar test E2E después de levantar"
      echo "  --no-build   No reconstruir imágenes de servicios"
      echo "  --stop       Solo parar todo y salir"
      echo "  --help       Mostrar esta ayuda"
      exit 0
      ;;
  esac
done

# --- Stop ---
if [ "$STOP_ONLY" = true ]; then
  log "Parando todos los servicios..."
  docker compose --profile app --profile infra down
  ok "Sistema parado"
  exit 0
fi

# --- 1. Infra ---
log "═══════════════════════════════════════"
log "  Paso 1/4: Levantando infraestructura"
log "═══════════════════════════════════════"

docker compose --profile infra up -d
ok "Contenedores infra arrancados"

# Esperar a que los brokers estén healthy
log "Esperando a que los brokers estén healthy..."

wait_healthy() {
  local service=$1
  local max_retries=${2:-60}
  local i=0
  while [ $i -lt $max_retries ]; do
    status=$(docker compose ps --format json "$service" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('Health',''))" 2>/dev/null || echo "")
    if [ "$status" = "healthy" ]; then
      ok "$service healthy"
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  fail "$service no respondió tras $((max_retries * 2))s"
  return 1
}

wait_healthy postgres 30
wait_healthy kafka 60
wait_healthy rabbitmq 30

# NATS (scratch image sin shell — check HTTP desde el host)
wait_http_quiet() {
  local name=$1
  local url=$2
  local max_retries=${3:-15}
  local i=0
  while [ $i -lt $max_retries ]; do
    if curl -sf "$url" > /dev/null 2>&1; then
      ok "$name healthy"
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  fail "$name no respondió tras $((max_retries * 2))s"
  return 1
}
wait_http_quiet nats "http://localhost:11025/healthz" 15

# --- 2. Apicurio Registry ---
log "═══════════════════════════════════════"
log "  Paso 2/4: Registrando schemas"
log "═══════════════════════════════════════"

wait_healthy apicurio-registry 30 || warn "Apicurio no está healthy, intentando registrar de todos modos..."

if bash "$SCRIPT_DIR/apicurio/register-schemas.sh" 2>/dev/null; then
  ok "Schemas registrados en Apicurio"
else
  warn "No se pudieron registrar schemas (no bloquea el sistema)"
fi

# --- 3. Servicios app ---
log "═══════════════════════════════════════"
log "  Paso 3/4: Levantando servicios app"
log "═══════════════════════════════════════"

if [ "$SKIP_BUILD" = true ]; then
  docker compose --profile infra --profile app up -d
else
  docker compose --profile infra --profile app up -d --build
fi
ok "Contenedores app arrancados"

# Esperar a que los servicios respondan
log "Esperando health checks de servicios..."

wait_http() {
  local name=$1
  local port=$2
  local max_retries=${3:-30}
  local i=0
  while [ $i -lt $max_retries ]; do
    if curl -sf "http://localhost:${port}/health" > /dev/null 2>&1; then
      ok "$name (localhost:$port)"
      return 0
    fi
    i=$((i + 1))
    sleep 2
  done
  fail "$name no respondió en localhost:$port tras $((max_retries * 2))s"
  return 1
}

SERVICES_OK=true
wait_http service-springboot 11001 60 || SERVICES_OK=false
wait_http service-quarkus    11002 60 || SERVICES_OK=false
wait_http service-go         11003 30 || SERVICES_OK=false
wait_http service-node       11004 30 || SERVICES_OK=false

# --- 4. Resumen ---
log "═══════════════════════════════════════"
log "  Paso 4/4: Resumen"
log "═══════════════════════════════════════"

echo ""
docker compose --profile infra --profile app ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

if [ "$SERVICES_OK" = true ]; then
  ok "Sistema completo levantado"
  echo ""
  echo "  Servicios:"
  echo "    SpringBoot  → http://localhost:11001"
  echo "    Quarkus     → http://localhost:11002"
  echo "    Go          → http://localhost:11003"
  echo "    Node        → http://localhost:11004"
  echo "    Frontend    → http://localhost:11000"
  echo ""
  echo "  Brokers:"
  echo "    Kafka       → localhost:11021"
  echo "    RabbitMQ    → localhost:11022 (management: http://localhost:11023)"
  echo "    NATS        → localhost:11024 (monitor: http://localhost:11025)"
  echo ""
  echo "  Infra:"
  echo "    PostgreSQL  → localhost:11010"
  echo "    Apicurio    → http://localhost:11011"
  echo ""
else
  fail "Algunos servicios no arrancaron correctamente"
  warn "Revisa los logs: docker compose --profile app logs"
fi

# --- E2E (opcional) ---
if [ "$RUN_E2E" = true ]; then
  echo ""
  log "═══════════════════════════════════════"
  log "  Ejecutando test E2E (84 combinaciones)"
  log "═══════════════════════════════════════"
  bash "$SCRIPT_DIR/test/e2e-matrix.sh"
fi

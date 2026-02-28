# CLAUDE.md — serialplab

## Proyecto

**serialplab** (Serialization Lab) es una PoC que evalúa la intercomunicación entre servicios heterogéneos usando 7 protocolos de serialización × 3 brokers de mensajería × 4 stacks tecnológicos (84 combinaciones).

**Estado actual:** Implementación completa. Los 4 servicios, schemas compartidos, docker-compose, scripts de codegen/test E2E, migraciones SQL, consumers y serialización real están implementados. Las 84 combinaciones están operativas.

## Estructura de carpetas

```
serialplab/
├── ARCHITECTURE.md          ← Arquitectura completa (leer siempre)
├── specs/                   ← Specs de implementación por componente
│   ├── services/            ← service-springboot, quarkus, go, node
│   ├── protocols/           ← protobuf, avro, thrift, msgpack, flatbuf, cbor, json-schema
│   ├── brokers/             ← kafka, rabbitmq, nats
│   ├── registros/           ← apicurio-registry
│   └── frontend/            ← frontend-angular
├── doc/                     ← Referencia técnica (conceptos, no impl)
├── scripts/ralph/           ← Orquestador Ralph
│   ├── ralph.sh             ← Script principal (paralelismo adaptativo)
│   ├── prd.json             ← Subtareas de la issue actual (generado)
│   ├── prompt-N.md          ← Prompt por subtarea (generado)
│   ├── timings.csv          ← Registro de tiempos por subtarea (generado)
│   ├── prompt.md.template   ← Template del prompt
│   └── prd.json.template    ← Template del prd.json
├── scripts/test/            ← Tests E2E y matriz de resultados
│   ├── e2e-matrix.sh        ← Script de test E2E (84 combinaciones)
│   └── results-template.md  ← Template de resultados
├── scripts/codegen/         ← Generación de código desde schemas
│   └── generate-all.sh      ← Genera código para todos los protocolos
├── scripts/apicurio/        ← Gestión del registro de schemas
│   ├── register-schemas.sh  ← Registra schemas en Apicurio
│   └── wait-for-registry.sh ← Espera a que el registry esté listo
├── apicurio/                ← Inicialización de Apicurio Registry
│   └── init-registry-db.sql ← Script SQL de inicialización
├── schemas/                 ← .proto, .avsc, .thrift, .fbs, .schema.json
├── asyncapi/                ← Contratos AsyncAPI yaml
├── service-springboot/      ← Java 21 + Spring Boot 3, puerto 11001
├── service-quarkus/         ← Java 21 + Quarkus, puerto 11002
├── service-go/              ← Go 1.22+, puerto 11003
├── service-node/            ← Node.js 22 + TS, puerto 11004
├── frontend-angular/        ← Angular 19, puerto 11000
└── docker-compose.yml       ← Perfiles: infra, app
```

## Convenciones

- **Idioma:** Documentación en español, código en inglés.
- **Puertos:** Rango 11xxx (ver ARCHITECTURE.md §2–§5).
- **Modelo de datos compartido:** `User` (definido en schemas/). Todos los servicios usan el mismo modelo.
- **Docker Compose:** Perfiles `infra` (brokers, BD, registry) y `app` (servicios + frontend).
- **Base de datos:** PostgreSQL 16 (:11010), un schema por servicio.
- **Sin sudo:** No ejecutar comandos que requieran `sudo`. Si una subtarea necesita `sudo`, crear una GitHub Issue nueva describiendo qué instalar/configurar y marcar la subtarea como bloqueada.
- **Commit siempre:** Cada subtarea que genere o modifique ficheros debe hacer `git add` + `git commit` + `git push` aunque la validación falle después. Es preferible subir código incorrecto y corregirlo en la siguiente iteración que perder el trabajo.

## Ficheros clave (leer para contexto)

| Fichero | Cuándo leerlo |
|---------|---------------|
| `ARCHITECTURE.md` | Siempre al inicio de sesión |
| `specs/services/<servicio>.md` | Al trabajar en un servicio específico |
| `specs/protocols/<protocolo>.md` | Al implementar un protocolo |
| `specs/brokers/<broker>.md` | Al configurar un broker |

## Workflow con Ralph

### Fuente de verdad: GitHub Issues

Todas las tareas están en GitHub Issues (`gh issue list`). No hay TODOs locales.

### Sesión interactiva (Claude Code)

1. **Seleccionar issue:** `gh issue list` → elegir la issue a abordar.
2. **Leer specs relevantes:** Según el tipo de issue, leer las specs correspondientes.
3. **Descomponer en subtareas:** Dividir la issue en micro-tareas atómicas (una por fichero/componente).
4. **Generar prd.json:** Crear `scripts/ralph/prd.json` siguiendo el template.
5. **Generar prompts:** Crear `scripts/ralph/prompt-N.md` por cada subtarea, siguiendo el template.
6. **Lanzar Ralph:** `./scripts/ralph/ralph.sh --tool claude`

### Formato de prd.json

```json
{
  "issueNumber": 1,
  "issueTitle": "Título de la issue",
  "branchName": "ralph/issue-1-descripcion-corta",
  "subtasks": [
    {
      "id": 1,
      "title": "Descripción corta de la subtarea",
      "promptFile": "prompt-1.md",
      "passes": false
    }
  ]
}
```

### Formato de prompt-N.md

Cada prompt contiene: objetivo, ficheros a crear/modificar, fragmentos de contexto relevantes (NO ficheros completos), criterios de aceptación y comando de validación. Ver `scripts/ralph/prompt.md.template`.

### Paralelismo adaptativo

Ralph ajusta automáticamente el número de subtareas en paralelo:

1. **Empieza con 1 subtarea** por iteración.
2. Si la subtarea termina en **< 5 minutos**, la siguiente iteración lanza **2 subtareas en paralelo**.
3. Si alguna subtarea en paralelo **tarda >= 5 minutos**, vuelve a **1 subtarea** y genera un **informe de tiempos**.

Al diseñar subtareas, tener en cuenta:
- Las subtareas que puedan ejecutarse en paralelo **no deben modificar los mismos ficheros**.
- Ordenar subtareas para que las independientes queden consecutivas (maximiza paralelismo).
- El informe de tiempos se guarda en `scripts/ralph/timings.csv` y se imprime en consola al revertir a 1 slot o al completar.

## Límite de contexto del LLM local: 32k tokens

Ralph ejecuta subtareas con un LLM que tiene ventana de 32k tokens. **Nunca pasar ficheros completos.** Solo incluir en el prompt:

- El método/clase/función relevante
- Interfaces directas que necesita
- Fragmentos de specs (no la spec entera)

## Señal de completado

Cuando todas las subtareas del prd.json tienen `passes: true`, imprimir:

```
<promise>COMPLETE</promise>
```

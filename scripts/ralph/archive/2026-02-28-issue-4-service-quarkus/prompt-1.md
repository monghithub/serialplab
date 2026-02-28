# Tarea: Go module + main.go con health endpoint y router

## Issue: #5
## Subtarea: 1 de 3

## Objetivo

Crear el módulo Go con main.go, router Chi, y health endpoint.

## Ficheros a crear

- `service-go/go.mod`
- `service-go/main.go`

## Contexto

Módulo: `serialplab/service-go`. Puerto: 11003. Usa Chi como router HTTP.

### go.mod

```
module serialplab/service-go

go 1.22

require (
	github.com/go-chi/chi/v5 v5.2.1
	github.com/lib/pq v1.10.9
	github.com/segmentio/kafka-go v0.4.47
	github.com/rabbitmq/amqp091-go v1.10.0
	github.com/nats-io/nats.go v1.38.0
	github.com/vmihailenco/msgpack/v5 v5.4.1
	github.com/fxamacker/cbor/v2 v2.7.0
)
```

**IMPORTANTE:** Solo genera el fichero `go.mod` con el contenido de arriba. NO generes `go.sum` — se generará automáticamente.

### main.go

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	log.Println("service-go starting on :11003")
	log.Fatal(http.ListenAndServe(":11003", r))
}
```

## Validación

```bash
test -f service-go/go.mod && test -f service-go/main.go && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

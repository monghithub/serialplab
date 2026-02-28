# Tarea: Handlers publish y messages + Dockerfile

## Issue: #5
## Subtarea: 3 de 3

## Objetivo

Crear los handlers HTTP para publish y messages, integrarlos en main.go, y crear el Dockerfile multi-stage.

## Ficheros a crear

- `service-go/internal/handler/handler.go`
- `service-go/Dockerfile`

## Ficheros a modificar

- `service-go/main.go` (añadir rutas de publish y messages)

## Contexto

### handler.go

```go
package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"serialplab/service-go/internal/broker"
	"serialplab/service-go/internal/db"
	"serialplab/service-go/internal/model"
	"serialplab/service-go/internal/serialization"
)

func PublishHandler(w http.ResponseWriter, r *http.Request) {
	target := chi.URLParam(r, "target")
	protocol := chi.URLParam(r, "protocol")
	brokerName := chi.URLParam(r, "broker")

	var user model.User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		http.Error(w, `{"error":"invalid body"}`, http.StatusBadRequest)
		return
	}

	data, err := serialization.Serialize(protocol, user)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusBadRequest)
		return
	}

	if err := broker.Publish(brokerName, target, protocol, data); err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	_ = db.SaveMessage(model.MessageLog{
		Direction: "sent", Protocol: protocol, Broker: brokerName,
		TargetService: target, UserID: user.ID, UserName: user.Name,
		UserEmail: user.Email, UserTimestamp: user.Timestamp,
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "published", "target": target,
		"protocol": protocol, "broker": brokerName,
	})
}

func MessagesHandler(w http.ResponseWriter, r *http.Request) {
	messages, err := db.GetMessages()
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}
	if messages == nil {
		messages = []model.MessageLog{}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(messages)
}
```

### main.go COMPLETO (reemplaza el existente)

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"serialplab/service-go/internal/db"
	"serialplab/service-go/internal/handler"
)

func main() {
	db.Init()

	r := chi.NewRouter()
	r.Use(middleware.Logger)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	r.Post("/publish/{target}/{protocol}/{broker}", handler.PublishHandler)
	r.Get("/messages", handler.MessagesHandler)

	log.Println("service-go starting on :11003")
	log.Fatal(http.ListenAndServe(":11003", r))
}
```

### Dockerfile

```dockerfile
FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o service-go .

FROM alpine:3.19
WORKDIR /app
COPY --from=build /app/service-go .
EXPOSE 11003
ENTRYPOINT ["./service-go"]
```

## Validación

```bash
test -f service-go/internal/handler/handler.go && test -f service-go/Dockerfile && grep -q "handler.PublishHandler" service-go/main.go && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

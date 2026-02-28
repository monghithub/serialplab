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
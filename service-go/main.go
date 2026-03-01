package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"serialplab/service-go/internal/broker"
	"serialplab/service-go/internal/db"
	"serialplab/service-go/internal/handler"
	"serialplab/service-go/internal/model"
	"serialplab/service-go/internal/serialization"
)

func main() {
	db.Init()

	broker.StartConsumers("service-go", func(brokerName, protocol string, data []byte, origin string) {
		user, err := serialization.Deserialize(protocol, data)
		if err != nil {
			log.Printf("[%s/%s] Deserialization error: %v", brokerName, protocol, err)
			return
		}
		log.Printf("[%s/%s] Received user: %s from %s", brokerName, protocol, user.ID, origin)
		_ = db.SaveMessage(model.MessageLog{
			Direction: "received", Protocol: protocol, Broker: brokerName,
			TargetService: "service-go", OriginService: origin, RawPayload: data,
			UserID: user.ID, UserName: user.Name,
			UserEmail: user.Email, UserTimestamp: user.Timestamp,
		})
	})

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
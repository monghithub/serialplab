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
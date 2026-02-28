package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
	"serialplab/service-go/internal/model"
)

var DB *sql.DB

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func Init() {
	var err error
	connStr := fmt.Sprintf("host=%s port=%s user=serialplab password=serialplab dbname=serialplab sslmode=disable search_path=goservice",
		envOr("DB_HOST", "localhost"), envOr("DB_PORT", "11010"))
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Printf("Warning: could not connect to DB: %v", err)
		return
	}

	_, _ = DB.Exec("CREATE SCHEMA IF NOT EXISTS goservice")
	_, _ = DB.Exec(`CREATE TABLE IF NOT EXISTS goservice.message_log (
		id SERIAL PRIMARY KEY,
		direction TEXT, protocol TEXT, broker TEXT, target_service TEXT,
		user_id TEXT, user_name TEXT, user_email TEXT, user_timestamp BIGINT,
		created_at TIMESTAMP DEFAULT NOW()
	)`)
}

func SaveMessage(m model.MessageLog) error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}
	_, err := DB.Exec(
		"INSERT INTO goservice.message_log (direction, protocol, broker, target_service, user_id, user_name, user_email, user_timestamp) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)",
		m.Direction, m.Protocol, m.Broker, m.TargetService, m.UserID, m.UserName, m.UserEmail, m.UserTimestamp,
	)
	return err
}

func GetMessages() ([]model.MessageLog, error) {
	if DB == nil {
		return nil, fmt.Errorf("database not initialized")
	}
	rows, err := DB.Query("SELECT id, direction, protocol, broker, target_service, user_id, user_name, user_email, user_timestamp, created_at FROM goservice.message_log ORDER BY created_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []model.MessageLog
	for rows.Next() {
		var m model.MessageLog
		if err := rows.Scan(&m.ID, &m.Direction, &m.Protocol, &m.Broker, &m.TargetService, &m.UserID, &m.UserName, &m.UserEmail, &m.UserTimestamp, &m.CreatedAt); err != nil {
			return nil, err
		}
		messages = append(messages, m)
	}
	return messages, nil
}
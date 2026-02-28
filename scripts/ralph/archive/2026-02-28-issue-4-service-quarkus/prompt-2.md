# Tarea: Modelo, DB, serialización y brokers

## Issue: #5
## Subtarea: 2 de 3

## Objetivo

Crear los paquetes internos: modelo, base de datos, serialización (7 protocolos) y brokers (Kafka, RabbitMQ, NATS).

## Ficheros a crear

- `service-go/internal/model/user.go`
- `service-go/internal/db/db.go`
- `service-go/internal/serialization/serialization.go`
- `service-go/internal/broker/broker.go`

## Contexto

### user.go

```go
package model

type User struct {
	ID        string `json:"id" msgpack:"id" cbor:"id"`
	Name      string `json:"name" msgpack:"name" cbor:"name"`
	Email     string `json:"email" msgpack:"email" cbor:"email"`
	Timestamp int64  `json:"timestamp" msgpack:"timestamp" cbor:"timestamp"`
}

type MessageLog struct {
	ID            int64  `json:"id"`
	Direction     string `json:"direction"`
	Protocol      string `json:"protocol"`
	Broker        string `json:"broker"`
	TargetService string `json:"target_service"`
	UserID        string `json:"user_id"`
	UserName      string `json:"user_name"`
	UserEmail     string `json:"user_email"`
	UserTimestamp int64  `json:"user_timestamp"`
	CreatedAt     string `json:"created_at"`
}
```

### db.go

PostgreSQL connection, schema `goservice`. Creates table if not exists.

```go
package db

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
	"serialplab/service-go/internal/model"
)

var DB *sql.DB

func Init() {
	var err error
	connStr := "host=localhost port=11010 user=serialplab password=serialplab dbname=serialplab sslmode=disable search_path=goservice"
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
```

### serialization.go

```go
package serialization

import (
	"encoding/json"

	"github.com/fxamacker/cbor/v2"
	"github.com/vmihailenco/msgpack/v5"
	"serialplab/service-go/internal/model"
)

func Serialize(protocol string, user model.User) ([]byte, error) {
	switch protocol {
	case "json", "json-schema":
		return json.Marshal(user)
	case "cbor":
		return cbor.Marshal(user)
	case "msgpack", "messagepack":
		return msgpack.Marshal(user)
	case "protobuf", "avro", "thrift", "flatbuffers":
		return json.Marshal(user) // placeholder
	default:
		return nil, fmt.Errorf("unknown protocol: %s", protocol)
	}
}

func Deserialize(protocol string, data []byte) (model.User, error) {
	var user model.User
	var err error
	switch protocol {
	case "json", "json-schema":
		err = json.Unmarshal(data, &user)
	case "cbor":
		err = cbor.Unmarshal(data, &user)
	case "msgpack", "messagepack":
		err = msgpack.Unmarshal(data, &user)
	case "protobuf", "avro", "thrift", "flatbuffers":
		err = json.Unmarshal(data, &user) // placeholder
	default:
		return user, fmt.Errorf("unknown protocol: %s", protocol)
	}
	return user, err
}
```

**IMPORTANTE:** Añadir `"fmt"` al import de serialization.go.

### broker.go

```go
package broker

import (
	"context"
	"fmt"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/segmentio/kafka-go"
	"github.com/nats-io/nats.go"
)

func Publish(brokerName, target, protocol string, data []byte) error {
	subject := fmt.Sprintf("serialplab.%s.%s", target, protocol)
	switch brokerName {
	case "kafka":
		return publishKafka(subject, data)
	case "rabbitmq":
		return publishRabbit(subject, data)
	case "nats":
		return publishNats(subject, data)
	default:
		return fmt.Errorf("unknown broker: %s", brokerName)
	}
}

func publishKafka(topic string, data []byte) error {
	w := &kafka.Writer{
		Addr:  kafka.TCP("localhost:11021"),
		Topic: topic,
	}
	defer w.Close()
	return w.WriteMessages(context.Background(), kafka.Message{Value: data})
}

func publishRabbit(routingKey string, data []byte) error {
	conn, err := amqp.Dial("amqp://guest:guest@localhost:11022/")
	if err != nil {
		return err
	}
	defer conn.Close()
	ch, err := conn.Channel()
	if err != nil {
		return err
	}
	defer ch.Close()
	return ch.Publish("", routingKey, false, false, amqp.Publishing{Body: data})
}

func publishNats(subject string, data []byte) error {
	nc, err := nats.Connect("nats://localhost:11024")
	if err != nil {
		return err
	}
	defer nc.Close()
	return nc.Publish(subject, data)
}
```

## Validación

```bash
test -f service-go/internal/model/user.go && test -f service-go/internal/db/db.go && test -f service-go/internal/serialization/serialization.go && test -f service-go/internal/broker/broker.go && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

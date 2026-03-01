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
	OriginService string `json:"origin_service"`
	RawPayload    []byte `json:"raw_payload"`
	UserID        string `json:"user_id"`
	UserName      string `json:"user_name"`
	UserEmail     string `json:"user_email"`
	UserTimestamp int64  `json:"user_timestamp"`
	CreatedAt     string `json:"created_at"`
}
-- Flyway migration: schema springboot
CREATE SCHEMA IF NOT EXISTS springboot;

CREATE TABLE IF NOT EXISTS springboot.message_log (
    id BIGSERIAL PRIMARY KEY,
    message_id UUID NOT NULL,
    broker VARCHAR(20) NOT NULL,
    protocol VARCHAR(20) NOT NULL,
    direction VARCHAR(10) NOT NULL,
    payload_size_bytes INTEGER,
    serialization_time_us BIGINT,
    deserialization_time_us BIGINT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_message_log_broker ON springboot.message_log(broker);
CREATE INDEX idx_message_log_protocol ON springboot.message_log(protocol);
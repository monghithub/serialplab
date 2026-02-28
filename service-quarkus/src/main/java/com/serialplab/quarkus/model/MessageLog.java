package com.serialplab.quarkus.model;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "message_log", schema = "quarkus")
public class MessageLog extends PanacheEntity {

    public String direction;
    public String protocol;
    public String broker;
    public String targetService;
    public String userId;
    public String userName;
    public String userEmail;
    public long userTimestamp;

    @Column(name = "created_at")
    public Instant createdAt = Instant.now();

    public MessageLog() {}

    public MessageLog(String direction, String protocol, String broker,
                      String targetService, String userId, String userName,
                      String userEmail, long userTimestamp) {
        this.direction = direction;
        this.protocol = protocol;
        this.broker = broker;
        this.targetService = targetService;
        this.userId = userId;
        this.userName = userName;
        this.userEmail = userEmail;
        this.userTimestamp = userTimestamp;
        this.createdAt = Instant.now();
    }
}
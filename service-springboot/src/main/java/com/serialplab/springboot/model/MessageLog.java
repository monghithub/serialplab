package com.serialplab.springboot.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "message_log", schema = "springboot")
public class MessageLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String direction; // "sent" or "received"
    private String protocol;
    private String broker;
    private String targetService;
    private String originService;

    @Column(name = "raw_payload")
    private byte[] rawPayload;

    private String userId;
    private String userName;
    private String userEmail;
    private long userTimestamp;

    @Column(name = "created_at")
    private Instant createdAt = Instant.now();

    public MessageLog() {}

    public MessageLog(String direction, String protocol, String broker,
                      String targetService, String originService, byte[] rawPayload,
                      String userId, String userName,
                      String userEmail, long userTimestamp) {
        this.direction = direction;
        this.protocol = protocol;
        this.broker = broker;
        this.targetService = targetService;
        this.originService = originService;
        this.rawPayload = rawPayload;
        this.userId = userId;
        this.userName = userName;
        this.userEmail = userEmail;
        this.userTimestamp = userTimestamp;
        this.createdAt = Instant.now();
    }

    public Long getId() { return id; }
    public String getDirection() { return direction; }
    public String getProtocol() { return protocol; }
    public String getBroker() { return broker; }
    public String getTargetService() { return targetService; }
    public String getOriginService() { return originService; }
    public byte[] getRawPayload() { return rawPayload; }
    public String getUserId() { return userId; }
    public String getUserName() { return userName; }
    public String getUserEmail() { return userEmail; }
    public long getUserTimestamp() { return userTimestamp; }
    public Instant getCreatedAt() { return createdAt; }
}
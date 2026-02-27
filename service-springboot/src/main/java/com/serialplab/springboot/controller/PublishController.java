package com.serialplab.springboot.controller;

import com.serialplab.springboot.broker.BrokerService;
import com.serialplab.springboot.model.MessageLog;
import com.serialplab.springboot.repository.MessageLogRepository;
import com.serialplab.springboot.serialization.SerializationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/publish")
public class PublishController {

    private final SerializationService serializationService;
    private final BrokerService brokerService;
    private final MessageLogRepository messageLogRepository;

    public PublishController(SerializationService serializationService,
                             BrokerService brokerService,
                             MessageLogRepository messageLogRepository) {
        this.serializationService = serializationService;
        this.brokerService = brokerService;
        this.messageLogRepository = messageLogRepository;
    }

    @PostMapping("/{target}/{protocol}/{broker}")
    public ResponseEntity<Map<String, String>> publish(
            @PathVariable String target,
            @PathVariable String protocol,
            @PathVariable String broker,
            @RequestBody Map<String, Object> user) {
        try {
            byte[] data = serializationService.serialize(protocol, user);
            brokerService.publish(broker, target, protocol, data);

            messageLogRepository.save(new MessageLog(
                "sent", protocol, broker, target,
                (String) user.get("id"),
                (String) user.get("name"),
                (String) user.get("email"),
                ((Number) user.get("timestamp")).longValue()
            ));

            return ResponseEntity.ok(Map.of(
                "status", "published",
                "target", target,
                "protocol", protocol,
                "broker", broker,
                "bytes", String.valueOf(data.length)
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", e.getMessage()));
        }
    }
}
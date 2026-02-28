package com.serialplab.springboot.controller;

import com.serialplab.springboot.model.MessageLog;
import com.serialplab.springboot.repository.MessageLogRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class MessagesController {

    private final MessageLogRepository messageLogRepository;

    public MessagesController(MessageLogRepository messageLogRepository) {
        this.messageLogRepository = messageLogRepository;
    }

    @GetMapping("/messages")
    public List<MessageLog> messages() {
        return messageLogRepository.findAllByOrderByCreatedAtDesc();
    }
}
package com.serialplab.springboot.repository;

import com.serialplab.springboot.model.MessageLog;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MessageLogRepository extends JpaRepository<MessageLog, Long> {
    List<MessageLog> findAllByOrderByCreatedAtDesc();
}
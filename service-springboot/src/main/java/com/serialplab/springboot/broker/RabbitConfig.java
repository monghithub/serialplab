package com.serialplab.springboot.broker;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class RabbitConfig {

    private static final String SERVICE_NAME = "service-springboot";
    private static final String EXCHANGE = "amq.topic";
    private static final String[] PROTOCOLS = {
        "protobuf", "avro", "thrift", "messagepack", "flatbuffers", "cbor", "json-schema"
    };

    @Bean
    public Declarables rabbitDeclarables() {
        List<Declarable> declarables = new ArrayList<>();
        TopicExchange exchange = new TopicExchange(EXCHANGE, true, false);
        for (String protocol : PROTOCOLS) {
            String queueName = "serialplab." + SERVICE_NAME + "." + protocol;
            Queue queue = new Queue(queueName, true);
            declarables.add(queue);
            declarables.add(BindingBuilder.bind(queue).to(exchange).with(queueName));
        }
        return new Declarables(declarables);
    }

    @Bean("rabbitQueues")
    public String[] rabbitQueues() {
        String[] queues = new String[PROTOCOLS.length];
        for (int i = 0; i < PROTOCOLS.length; i++) {
            queues[i] = "serialplab." + SERVICE_NAME + "." + PROTOCOLS[i];
        }
        return queues;
    }

    @Bean
    public AmqpTemplate amqpTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setExchange(EXCHANGE);
        return template;
    }
}

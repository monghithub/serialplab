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
    public TopicExchange topicExchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    public List<Queue> protocolQueues() {
        List<Queue> queues = new ArrayList<>();
        for (String protocol : PROTOCOLS) {
            queues.add(new Queue("serialplab." + SERVICE_NAME + "." + protocol, true));
        }
        return queues;
    }

    @Bean
    public List<Binding> protocolBindings(TopicExchange topicExchange, List<Queue> protocolQueues) {
        List<Binding> bindings = new ArrayList<>();
        for (Queue queue : protocolQueues) {
            bindings.add(BindingBuilder.bind(queue).to(topicExchange).with(queue.getName()));
        }
        return bindings;
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
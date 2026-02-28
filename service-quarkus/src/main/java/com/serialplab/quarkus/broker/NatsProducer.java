package com.serialplab.quarkus.broker;

import io.nats.client.Connection;
import io.nats.client.Nats;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class NatsProducer {

    @ConfigProperty(name = "nats.url", defaultValue = "nats://localhost:11024")
    String natsUrl;

    @Produces
    @ApplicationScoped
    public Connection natsConnection() throws Exception {
        return Nats.connect(natsUrl);
    }
}
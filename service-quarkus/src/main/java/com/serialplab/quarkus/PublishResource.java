package com.serialplab.quarkus;

import com.serialplab.quarkus.broker.BrokerService;
import com.serialplab.quarkus.model.MessageLog;
import com.serialplab.quarkus.serialization.SerializationService;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.Map;

@Path("/publish")
public class PublishResource {

    @Inject
    SerializationService serializationService;

    @Inject
    BrokerService brokerService;

    @POST
    @Path("/{target}/{protocol}/{broker}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Transactional
    public Response publish(@PathParam("target") String target,
                            @PathParam("protocol") String protocol,
                            @PathParam("broker") String broker,
                            Map<String, Object> user) {
        try {
            byte[] data = serializationService.serialize(protocol, user);
            brokerService.publish(broker, target, protocol, data);

            var log = new MessageLog(
                "sent", protocol, broker, target,
                (String) user.get("id"),
                (String) user.get("name"),
                (String) user.get("email"),
                ((Number) user.get("timestamp")).longValue()
            );
            log.persist();

            return Response.ok(Map.of(
                "status", "published",
                "target", target,
                "protocol", protocol,
                "broker", broker,
                "bytes", String.valueOf(data.length)
            )).build();
        } catch (Exception e) {
            return Response.serverError()
                .entity(Map.of("error", e.getMessage()))
                .build();
        }
    }
}
package com.serialplab.quarkus;

import com.serialplab.quarkus.model.MessageLog;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.List;

@Path("/messages")
public class MessagesResource {

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<MessageLog> messages() {
        return MessageLog.listAll();
    }
}
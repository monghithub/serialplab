# Tarea: Proyecto Maven Quarkus + application.properties + HealthResource

## Issue: #4
## Subtarea: 1 de 4

## Objetivo

Crear el esqueleto del proyecto Quarkus con Maven: pom.xml, application.properties, y health endpoint.

## Ficheros a crear

- `service-quarkus/pom.xml`
- `service-quarkus/src/main/resources/application.properties`
- `service-quarkus/src/main/java/com/serialplab/quarkus/HealthResource.java`

## Contexto

Base package: `com.serialplab.quarkus`. Puerto: 11002. PostgreSQL en localhost:11010, schema `quarkus`. Quarkus usa JAX-RS (no Spring MVC).

### pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.serialplab</groupId>
    <artifactId>service-quarkus</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties>
        <quarkus.platform.version>3.17.5</quarkus.platform.version>
        <compiler-plugin.version>3.13.0</compiler-plugin.version>
        <maven.compiler.release>21</maven.compiler.release>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>io.quarkus.platform</groupId>
                <artifactId>quarkus-bom</artifactId>
                <version>${quarkus.platform.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-rest-jackson</artifactId>
        </dependency>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-hibernate-orm-panache</artifactId>
        </dependency>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-jdbc-postgresql</artifactId>
        </dependency>
        <!-- NATS -->
        <dependency>
            <groupId>io.nats</groupId>
            <artifactId>jnats</artifactId>
            <version>2.20.5</version>
        </dependency>
        <!-- Protobuf -->
        <dependency>
            <groupId>com.google.protobuf</groupId>
            <artifactId>protobuf-java</artifactId>
            <version>4.29.3</version>
        </dependency>
        <!-- Avro -->
        <dependency>
            <groupId>org.apache.avro</groupId>
            <artifactId>avro</artifactId>
            <version>1.12.0</version>
        </dependency>
        <!-- Thrift -->
        <dependency>
            <groupId>org.apache.thrift</groupId>
            <artifactId>libthrift</artifactId>
            <version>0.21.0</version>
        </dependency>
        <!-- MessagePack -->
        <dependency>
            <groupId>org.msgpack</groupId>
            <artifactId>msgpack-core</artifactId>
            <version>0.9.8</version>
        </dependency>
        <!-- FlatBuffers -->
        <dependency>
            <groupId>com.google.flatbuffers</groupId>
            <artifactId>flatbuffers-java</artifactId>
            <version>24.12.23</version>
        </dependency>
        <!-- CBOR -->
        <dependency>
            <groupId>com.fasterxml.jackson.dataformat</groupId>
            <artifactId>jackson-dataformat-cbor</artifactId>
        </dependency>
        <!-- JSON Schema Validator -->
        <dependency>
            <groupId>com.networknt</groupId>
            <artifactId>json-schema-validator</artifactId>
            <version>1.5.4</version>
        </dependency>
        <!-- Test -->
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-junit5</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>io.quarkus.platform</groupId>
                <artifactId>quarkus-maven-plugin</artifactId>
                <version>${quarkus.platform.version}</version>
                <extensions>true</extensions>
                <executions>
                    <execution>
                        <goals>
                            <goal>build</goal>
                            <goal>generate-code</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>${compiler-plugin.version}</version>
                <configuration>
                    <release>${maven.compiler.release}</release>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### application.properties

```properties
quarkus.http.port=11002

# Datasource
quarkus.datasource.db-kind=postgresql
quarkus.datasource.username=serialplab
quarkus.datasource.password=serialplab
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:11010/serialplab?currentSchema=quarkus
quarkus.hibernate-orm.database.default-schema=quarkus
quarkus.hibernate-orm.database.generation=update

# NATS
nats.url=nats://localhost:11024
```

### HealthResource.java

```java
package com.serialplab.quarkus;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import java.util.Map;

@Path("/health")
public class HealthResource {
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }
}
```

## Validación

```bash
test -f service-quarkus/pom.xml && test -f service-quarkus/src/main/resources/application.properties && test -f service-quarkus/src/main/java/com/serialplab/quarkus/HealthResource.java && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

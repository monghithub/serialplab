# Tarea: Script de codegen + Maven plugins para Java services

## Issue: #20
## Subtarea: 1 de 2

## Objetivo

Crear un script maestro de generación de código y añadir los Maven plugins de protobuf y avro a ambos pom.xml de los servicios Java.

## Ficheros a crear/modificar

- `scripts/codegen/generate-all.sh` (crear)
- `service-springboot/pom.xml` (modificar - contenido COMPLETO abajo)
- `service-quarkus/pom.xml` (modificar - contenido COMPLETO abajo)

## Contexto

Los schemas están en `schemas/`. Necesitamos:
1. Un script bash que invoque protoc, thrift y flatc para generar código
2. Maven plugins para protobuf y avro en ambos servicios Java

### scripts/codegen/generate-all.sh

```bash
#!/usr/bin/env bash
# Genera código fuente desde los schemas compartidos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCHEMAS_DIR="${PROJECT_ROOT}/schemas"

echo "=== Code Generation from Schemas ==="
echo ""

# --- Protobuf ---
echo "1/4 Protobuf (protoc)..."
if command -v protoc &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  protoc --java_out="${PROJECT_ROOT}/service-springboot/src/main/java" \
    --proto_path="${SCHEMAS_DIR}/protobuf" \
    "${SCHEMAS_DIR}/protobuf/message.proto"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  if command -v protoc-gen-go &>/dev/null; then
    mkdir -p "${PROJECT_ROOT}/service-go/internal/proto"
    protoc --go_out="${PROJECT_ROOT}/service-go/internal/proto" \
      --go_opt=paths=source_relative \
      --proto_path="${SCHEMAS_DIR}/protobuf" \
      "${SCHEMAS_DIR}/protobuf/message.proto"
  fi
  # Node/TS
  if command -v npx &>/dev/null; then
    mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
    npx pbjs -t static-module -w es6 -o "${PROJECT_ROOT}/service-node/src/generated/message.js" \
      "${SCHEMAS_DIR}/protobuf/message.proto" 2>/dev/null || true
    npx pbts -o "${PROJECT_ROOT}/service-node/src/generated/message.d.ts" \
      "${PROJECT_ROOT}/service-node/src/generated/message.js" 2>/dev/null || true
  fi
  echo "  OK"
else
  echo "  SKIP: protoc not found"
fi

# --- Avro ---
echo "2/4 Avro..."
echo "  Java: handled by avro-maven-plugin in pom.xml"
echo "  Go/Node: use dynamic schema loading (no codegen needed)"

# --- Thrift ---
echo "3/4 Thrift..."
if command -v thrift &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  thrift --gen java -out "${PROJECT_ROOT}/service-springboot/src/main/java" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  mkdir -p "${PROJECT_ROOT}/service-go/internal/thriftgen"
  thrift --gen go -out "${PROJECT_ROOT}/service-go/internal/thriftgen" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  # Node
  mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
  thrift --gen js:node -out "${PROJECT_ROOT}/service-node/src/generated" \
    "${SCHEMAS_DIR}/thrift/message.thrift"
  echo "  OK"
else
  echo "  SKIP: thrift not found"
fi

# --- FlatBuffers ---
echo "4/4 FlatBuffers (flatc)..."
if command -v flatc &>/dev/null; then
  # Java
  mkdir -p "${PROJECT_ROOT}/service-springboot/src/main/java"
  flatc --java -o "${PROJECT_ROOT}/service-springboot/src/main/java" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  cp -r "${PROJECT_ROOT}/service-springboot/src/main/java/com" \
    "${PROJECT_ROOT}/service-quarkus/src/main/java/" 2>/dev/null || true
  # Go
  mkdir -p "${PROJECT_ROOT}/service-go/internal/flatgen"
  flatc --go -o "${PROJECT_ROOT}/service-go/internal/flatgen" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  # Node/TS
  mkdir -p "${PROJECT_ROOT}/service-node/src/generated"
  flatc --ts -o "${PROJECT_ROOT}/service-node/src/generated" \
    "${SCHEMAS_DIR}/flatbuffers/message.fbs"
  echo "  OK"
else
  echo "  SKIP: flatc not found"
fi

echo ""
echo "=== Code generation complete ==="
```

### service-springboot/pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.4.2</version>
    </parent>
    <groupId>com.serialplab</groupId>
    <artifactId>service-springboot</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>service-springboot</name>
    <properties>
        <java.version>21</java.version>
        <protobuf.version>4.29.3</protobuf.version>
        <avro.version>1.12.0</avro.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <!-- Kafka -->
        <dependency>
            <groupId>org.springframework.kafka</groupId>
            <artifactId>spring-kafka</artifactId>
        </dependency>
        <!-- RabbitMQ -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-amqp</artifactId>
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
            <version>${protobuf.version}</version>
        </dependency>
        <!-- Avro -->
        <dependency>
            <groupId>org.apache.avro</groupId>
            <artifactId>avro</artifactId>
            <version>${avro.version}</version>
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
        <!-- CBOR (Jackson) -->
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
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.avro</groupId>
                <artifactId>avro-maven-plugin</artifactId>
                <version>${avro.version}</version>
                <executions>
                    <execution>
                        <phase>generate-sources</phase>
                        <goals>
                            <goal>schema</goal>
                        </goals>
                        <configuration>
                            <sourceDirectory>${project.basedir}/../schemas/avro</sourceDirectory>
                            <outputDirectory>${project.build.directory}/generated-sources/avro</outputDirectory>
                            <stringType>String</stringType>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

### service-quarkus/pom.xml

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
        <protobuf.version>4.29.3</protobuf.version>
        <avro.version>1.12.0</avro.version>
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
            <version>${protobuf.version}</version>
        </dependency>
        <!-- Avro -->
        <dependency>
            <groupId>org.apache.avro</groupId>
            <artifactId>avro</artifactId>
            <version>${avro.version}</version>
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
            <plugin>
                <groupId>org.apache.avro</groupId>
                <artifactId>avro-maven-plugin</artifactId>
                <version>${avro.version}</version>
                <executions>
                    <execution>
                        <phase>generate-sources</phase>
                        <goals>
                            <goal>schema</goal>
                        </goals>
                        <configuration>
                            <sourceDirectory>${project.basedir}/../schemas/avro</sourceDirectory>
                            <outputDirectory>${project.build.directory}/generated-sources/avro</outputDirectory>
                            <stringType>String</stringType>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

## Validación

```bash
test -f scripts/codegen/generate-all.sh && grep -q "avro-maven-plugin" service-springboot/pom.xml && grep -q "avro-maven-plugin" service-quarkus/pom.xml && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

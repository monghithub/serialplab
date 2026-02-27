# NATS

## Descripción

Sistema de mensajería ligero y de alta performance. Pub/sub simple con baja latencia. Soporta JetStream para persistencia y streaming.

## Características

| Propiedad | Valor |
|---|---|
| Protocolo nativo | TCP texto/binario |
| Puertos | 11024 (cliente), 11025 (monitoring) |
| Imagen Docker | `nats:latest` |
| Dependencias | Ninguna |
| Paradigma | Pub/sub, request/reply, queue groups |

## Configuración Docker Compose

```yaml
nats:
  image: nats:latest
  command: ["--js", "--http_port", "11025"]
  ports:
    - "11024:11024"
    - "11025:11025"
```

## Subjects utilizados

| Subject | Descripción |
|---|---|
| `serialplab.messages` | Subject principal para intercambio de mensajes |
| `serialplab.benchmarks` | Resultados de benchmarks |

## Librerías cliente por stack

| Stack | Librería | Notas |
|---|---|---|
| Spring Boot | `io.nats:jnats` | Cliente oficial Java |
| Quarkus | `io.nats:jnats` | Cliente oficial Java |
| Go | `github.com/nats-io/nats.go` | Cliente oficial Go |
| Node.js | `nats` | Cliente oficial Node.js |

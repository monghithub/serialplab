# Specs — serialplab

Documentación modular de los componentes del proyecto. Cada spec describe un servicio, protocolo de serialización o broker de mensajería.

## Contenido

| Carpeta | Descripción | Cantidad |
|---|---|---|
| [services/](services/) | Servicios de aplicación (stacks tecnológicos) | 4 |
| [protocols/](protocols/) | Protocolos de serialización | 7 |
| [brokers/](brokers/) | Sistemas de mensajería | 3 |
| [registros/](registros/) | Registros de schemas y APIs | 1 |

## Navegación

Las specs de servicios enlazan a los protocolos y brokers que soportan. Esto permite consultar las dependencias y librerías específicas de cada combinación.

```
services/service-*.md
    ├── enlaza a → protocols/*.md   (protocolos soportados)
    ├── enlaza a → brokers/*.md     (brokers soportados)
    └── enlaza a → registros/*.md   (registros de schemas)
```

## Combinaciones totales

- **4** servicios × **7** protocolos × **3** brokers = **84 combinaciones**

Ver [ARCHITECTURE.md](../ARCHITECTURE.md) para la visión general del proyecto.

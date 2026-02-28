import { Injectable } from '@angular/core';

export interface ServiceInfo {
  name: string;
}

@Injectable({ providedIn: 'root' })
export class ConfigService {
  readonly services: ServiceInfo[] = [
    { name: 'service-springboot' },
    { name: 'service-quarkus' },
    { name: 'service-go' },
    { name: 'service-node' },
  ];

  readonly protocols = ['json-schema', 'protobuf', 'avro', 'thrift', 'messagepack', 'flatbuffers', 'cbor'];
  readonly brokers = ['kafka', 'rabbitmq', 'nats'];
}

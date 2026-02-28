import { Injectable } from '@angular/core';

export interface ServiceInfo {
  name: string;
  host: string;
  port: number;
}

@Injectable({ providedIn: 'root' })
export class ConfigService {
  readonly services: ServiceInfo[] = [
    { name: 'service-springboot', host: 'localhost', port: 11001 },
    { name: 'service-quarkus', host: 'localhost', port: 11002 },
    { name: 'service-go', host: 'localhost', port: 11003 },
    { name: 'service-node', host: 'localhost', port: 11004 },
  ];

  readonly protocols = ['json-schema', 'protobuf', 'avro', 'thrift', 'messagepack', 'flatbuffers', 'cbor'];
  readonly brokers = ['kafka', 'rabbitmq', 'nats'];
}
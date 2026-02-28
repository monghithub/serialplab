# Tarea: Services, Dashboard y CRUD components

## Issue: #7
## Subtarea: 2 de 3

## Objetivo

Crear los Angular services (ApiService, ConfigService) y los componentes Dashboard y CRUD.

## Ficheros a crear

- `frontend-angular/src/app/services/config.service.ts`
- `frontend-angular/src/app/services/api.service.ts`
- `frontend-angular/src/app/dashboard/dashboard.component.ts`
- `frontend-angular/src/app/crud/crud.component.ts`

## Contexto

Todos los componentes son standalone (Angular 19). Los servicios se inyectan con `inject()`.

### config.service.ts

```typescript
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
```

### api.service.ts

```typescript
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ConfigService, ServiceInfo } from './config.service';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);
  private config = inject(ConfigService);

  health(service: ServiceInfo): Observable<any> {
    return this.http.get(`http://${service.host}:${service.port}/health`);
  }

  publish(origin: ServiceInfo, target: string, protocol: string, broker: string, user: any): Observable<any> {
    const url = `http://${origin.host}:${origin.port}/publish/${target}/${protocol}/${broker}`;
    return this.http.post(url, user);
  }

  messages(service: ServiceInfo): Observable<any[]> {
    return this.http.get<any[]>(`http://${service.host}:${service.port}/messages`);
  }
}
```

### dashboard.component.ts

```typescript
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ConfigService, ServiceInfo } from '../services/config.service';
import { ApiService } from '../services/api.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h2>Dashboard</h2>
    <table>
      <thead><tr><th>Service</th><th>Port</th><th>Status</th></tr></thead>
      <tbody>
        <tr *ngFor="let s of statuses">
          <td>{{ s.service.name }}</td>
          <td>{{ s.service.port }}</td>
          <td [class]="s.ok ? 'status-ok' : 'status-down'">{{ s.ok ? 'OK' : 'DOWN' }}</td>
        </tr>
      </tbody>
    </table>
  `
})
export class DashboardComponent implements OnInit {
  private config = inject(ConfigService);
  private api = inject(ApiService);
  statuses: { service: ServiceInfo; ok: boolean }[] = [];

  ngOnInit() {
    this.statuses = this.config.services.map(s => ({ service: s, ok: false }));
    this.config.services.forEach((s, i) => {
      this.api.health(s).subscribe({
        next: () => this.statuses[i].ok = true,
        error: () => this.statuses[i].ok = false,
      });
    });
  }
}
```

### crud.component.ts

```typescript
import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConfigService } from '../services/config.service';
import { ApiService } from '../services/api.service';

@Component({
  selector: 'app-crud',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <h2>Publish Message</h2>
    <div>
      <label>Origin:
        <select [(ngModel)]="originIdx">
          <option *ngFor="let s of config.services; let i = index" [value]="i">{{ s.name }}</option>
        </select>
      </label>
      <label>Target:
        <select [(ngModel)]="target">
          <option *ngFor="let s of config.services" [value]="s.name">{{ s.name }}</option>
        </select>
      </label>
      <label>Protocol:
        <select [(ngModel)]="protocol">
          <option *ngFor="let p of config.protocols" [value]="p">{{ p }}</option>
        </select>
      </label>
      <label>Broker:
        <select [(ngModel)]="broker">
          <option *ngFor="let b of config.brokers" [value]="b">{{ b }}</option>
        </select>
      </label>
    </div>
    <div>
      <input [(ngModel)]="userName" placeholder="Name">
      <input [(ngModel)]="userEmail" placeholder="Email">
      <button (click)="send()">Send</button>
    </div>
    <div *ngIf="result">
      <h3>Result</h3>
      <pre>{{ result | json }}</pre>
    </div>
    <h3>Messages</h3>
    <button (click)="loadMessages()">Refresh</button>
    <table *ngIf="messages.length">
      <thead><tr><th>Direction</th><th>Protocol</th><th>Broker</th><th>Target</th><th>User</th><th>Time</th></tr></thead>
      <tbody>
        <tr *ngFor="let m of messages">
          <td>{{ m.direction }}</td><td>{{ m.protocol }}</td><td>{{ m.broker }}</td>
          <td>{{ m.targetService || m.target_service }}</td>
          <td>{{ m.userName || m.user_name }}</td><td>{{ m.createdAt || m.created_at }}</td>
        </tr>
      </tbody>
    </table>
  `
})
export class CrudComponent {
  config = inject(ConfigService);
  private api = inject(ApiService);

  originIdx = 0;
  target = 'service-quarkus';
  protocol = 'json-schema';
  broker = 'kafka';
  userName = '';
  userEmail = '';
  result: any = null;
  messages: any[] = [];

  send() {
    const origin = this.config.services[this.originIdx];
    const user = {
      id: crypto.randomUUID(),
      name: this.userName,
      email: this.userEmail,
      timestamp: Date.now()
    };
    this.api.publish(origin, this.target, this.protocol, this.broker, user).subscribe({
      next: res => this.result = res,
      error: err => this.result = { error: err.message },
    });
  }

  loadMessages() {
    const origin = this.config.services[this.originIdx];
    this.api.messages(origin).subscribe({
      next: msgs => this.messages = msgs,
      error: () => this.messages = [],
    });
  }
}
```

## Validación

```bash
test -f frontend-angular/src/app/services/config.service.ts && test -f frontend-angular/src/app/services/api.service.ts && test -f frontend-angular/src/app/dashboard/dashboard.component.ts && test -f frontend-angular/src/app/crud/crud.component.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

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
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ConfigService, ServiceInfo } from '../services/config.service';
import { ApiService } from '../services/api.service';

@Component({
  selector: 'app-database',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h2>Database — Message Log</h2>
    <button (click)="refreshAll()">Refresh All</button>
    <div *ngFor="let entry of entries">
      <h3>{{ entry.service.name }}</h3>
      <p *ngIf="entry.loading">Loading...</p>
      <p *ngIf="!entry.loading && entry.error">Error: {{ entry.error }}</p>
      <p *ngIf="!entry.loading && !entry.error && entry.messages.length === 0">No messages</p>
      <table *ngIf="entry.messages.length > 0">
        <thead>
          <tr>
            <th>Direction</th><th>Protocol</th><th>Broker</th>
            <th>Origin</th><th>Target</th>
            <th>Name</th><th>Email</th>
            <th>Raw Payload</th><th>Created At</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let m of entry.messages" [class]="m.direction">
            <td>{{ m.direction }}</td>
            <td>{{ m.protocol }}</td>
            <td>{{ m.broker }}</td>
            <td>{{ m.originService || m.origin_service || m.originservice || '-' }}</td>
            <td>{{ m.targetService || m.target_service || m.targetservice || '-' }}</td>
            <td>{{ m.userName || m.user_name || m.username }}</td>
            <td>{{ m.userEmail || m.user_email || m.useremail }}</td>
            <td class="raw"><code>{{ formatRaw(m.rawPayload || m.raw_payload || m.rawpayload) }}</code></td>
            <td>{{ m.createdAt || m.created_at }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    tr.sent td:first-child { color: #2196F3; font-weight: bold; }
    tr.received td:first-child { color: #4CAF50; font-weight: bold; }
    td.raw { max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 0.85em; }
    td.raw code { background: #f5f5f5; padding: 2px 4px; border-radius: 3px; }
  `]
})
export class DatabaseComponent implements OnInit {
  private config = inject(ConfigService);
  private api = inject(ApiService);

  entries: { service: ServiceInfo; messages: any[]; loading: boolean; error: string | null }[] = [];

  ngOnInit() {
    this.entries = this.config.services.map(s => ({ service: s, messages: [], loading: false, error: null }));
    this.refreshAll();
  }

  refreshAll() {
    this.entries.forEach((entry) => {
      entry.loading = true;
      entry.error = null;
      this.api.messages(entry.service).subscribe({
        next: msgs => { entry.messages = msgs; entry.loading = false; },
        error: err => { entry.error = err.message; entry.messages = []; entry.loading = false; },
      });
    });
  }

  formatRaw(payload: any): string {
    if (!payload) return '-';
    if (typeof payload === 'string') {
      // Base64 or hex — show first 60 chars
      return payload.length > 60 ? payload.substring(0, 60) + '...' : payload;
    }
    if (payload.data && Array.isArray(payload.data)) {
      // Node pg returns Buffer as {type: 'Buffer', data: [...]}
      const hex = payload.data.map((b: number) => b.toString(16).padStart(2, '0')).join('');
      return hex.length > 60 ? hex.substring(0, 60) + '...' : hex;
    }
    return String(payload).substring(0, 60);
  }
}

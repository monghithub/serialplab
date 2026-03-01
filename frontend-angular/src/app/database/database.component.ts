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
            <th>Target</th><th>Name</th><th>Email</th><th>Created At</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let m of entry.messages">
            <td>{{ m.direction }}</td>
            <td>{{ m.protocol }}</td>
            <td>{{ m.broker }}</td>
            <td>{{ m.targetService || m.target_service }}</td>
            <td>{{ m.userName || m.user_name }}</td>
            <td>{{ m.userEmail || m.user_email }}</td>
            <td>{{ m.createdAt || m.created_at }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  `
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
    this.entries.forEach((entry, i) => {
      entry.loading = true;
      entry.error = null;
      this.api.messages(entry.service).subscribe({
        next: msgs => { entry.messages = msgs; entry.loading = false; },
        error: err => { entry.error = err.message; entry.messages = []; entry.loading = false; },
      });
    });
  }
}

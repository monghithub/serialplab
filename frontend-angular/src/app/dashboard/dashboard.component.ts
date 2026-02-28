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
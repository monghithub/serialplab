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
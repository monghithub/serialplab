import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ServiceInfo } from './config.service';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private http = inject(HttpClient);

  health(service: ServiceInfo): Observable<any> {
    return this.http.get(`/api/${service.name}/health`);
  }

  publish(origin: ServiceInfo, target: string, protocol: string, broker: string, user: any): Observable<any> {
    return this.http.post(`/api/${origin.name}/publish/${target}/${protocol}/${broker}`, user);
  }

  messages(service: ServiceInfo): Observable<any[]> {
    return this.http.get<any[]>(`/api/${service.name}/messages`);
  }
}

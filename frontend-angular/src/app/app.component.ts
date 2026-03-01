import { Component } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink],
  template: `
    <nav>
      <a routerLink="/">Dashboard</a> |
      <a routerLink="/crud">CRUD</a> |
      <a routerLink="/database">Database</a> |
      <a href="https://kafka.serialplab.monghit.com" target="_blank">Kafka UI</a> |
      <a href="https://rabbitmq.serialplab.monghit.com" target="_blank">RabbitMQ</a> |
      <a href="https://nats.serialplab.monghit.com" target="_blank">NATS</a>
    </nav>
    <router-outlet></router-outlet>
  `
})
export class AppComponent {}
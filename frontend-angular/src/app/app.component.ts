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
      <a routerLink="/database">Database</a>
    </nav>
    <router-outlet></router-outlet>
  `
})
export class AppComponent {}
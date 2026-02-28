import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', loadComponent: () => import('./dashboard/dashboard.component').then(m => m.DashboardComponent) },
  { path: 'crud', loadComponent: () => import('./crud/crud.component').then(m => m.CrudComponent) },
];
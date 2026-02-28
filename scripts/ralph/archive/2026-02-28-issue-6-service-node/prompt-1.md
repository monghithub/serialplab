# Tarea: Proyecto Angular: package.json, angular.json, tsconfig, main.ts, app component

## Issue: #7
## Subtarea: 1 de 3

## Objetivo

Crear el esqueleto del proyecto Angular 19 con standalone components.

## Ficheros a crear

- `frontend-angular/package.json`
- `frontend-angular/angular.json`
- `frontend-angular/tsconfig.json`
- `frontend-angular/tsconfig.app.json`
- `frontend-angular/src/main.ts`
- `frontend-angular/src/index.html`
- `frontend-angular/src/styles.css`
- `frontend-angular/src/app/app.component.ts`
- `frontend-angular/src/app/app.routes.ts`

## Contexto

Angular 19 con standalone components (NO NgModules). Puerto: 11000.

### package.json

```json
{
  "name": "frontend-angular",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "ng": "ng",
    "start": "ng serve --port 11000",
    "build": "ng build",
    "test": "ng test --watch=false --browsers=ChromeHeadless"
  },
  "dependencies": {
    "@angular/animations": "^19.1.0",
    "@angular/common": "^19.1.0",
    "@angular/compiler": "^19.1.0",
    "@angular/core": "^19.1.0",
    "@angular/forms": "^19.1.0",
    "@angular/platform-browser": "^19.1.0",
    "@angular/platform-browser-dynamic": "^19.1.0",
    "@angular/router": "^19.1.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.8.0",
    "zone.js": "~0.15.0"
  },
  "devDependencies": {
    "@angular/build": "^19.1.0",
    "@angular/cli": "^19.1.0",
    "@angular/compiler-cli": "^19.1.0",
    "typescript": "~5.7.0"
  }
}
```

### angular.json

```json
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "frontend-angular": {
      "projectType": "application",
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "outputPath": "dist/frontend-angular",
            "index": "src/index.html",
            "browser": "src/main.ts",
            "tsConfig": "tsconfig.app.json",
            "styles": ["src/styles.css"]
          },
          "configurations": {
            "production": {
              "budgets": [{"type": "initial", "maximumWarning": "500kB", "maximumError": "1MB"}],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular/build:dev-server",
          "configurations": {
            "production": {"buildTarget": "frontend-angular:build:production"},
            "development": {"buildTarget": "frontend-angular:build:development"}
          },
          "defaultConfiguration": "development"
        }
      }
    }
  }
}
```

### tsconfig.json

```json
{
  "compileOnSave": false,
  "compilerOptions": {
    "outDir": "./dist/out-tsc",
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "sourceMap": true,
    "declaration": false,
    "downlevelIteration": true,
    "experimentalDecorators": true,
    "moduleResolution": "bundler",
    "importHelpers": true,
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022", "dom"],
    "skipLibCheck": true
  }
}
```

### tsconfig.app.json

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/app"
  },
  "files": ["src/main.ts"],
  "include": ["src/**/*.d.ts"]
}
```

### src/main.ts

```typescript
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { AppComponent } from './app/app.component';
import { routes } from './app/app.routes';

bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes),
    provideHttpClient()
  ]
});
```

### src/index.html

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>serialplab</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <app-root></app-root>
</body>
</html>
```

### src/styles.css

```css
body { font-family: sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
table { width: 100%; border-collapse: collapse; margin-top: 16px; }
th, td { padding: 8px 12px; border: 1px solid #ddd; text-align: left; }
th { background: #333; color: white; }
select, input, button { padding: 8px; margin: 4px; }
button { cursor: pointer; background: #1976d2; color: white; border: none; border-radius: 4px; }
.status-ok { color: green; }
.status-down { color: red; }
```

### src/app/app.component.ts

```typescript
import { Component } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink],
  template: `
    <nav>
      <a routerLink="/">Dashboard</a> |
      <a routerLink="/crud">CRUD</a>
    </nav>
    <router-outlet></router-outlet>
  `
})
export class AppComponent {}
```

### src/app/app.routes.ts

```typescript
import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', loadComponent: () => import('./dashboard/dashboard.component').then(m => m.DashboardComponent) },
  { path: 'crud', loadComponent: () => import('./crud/crud.component').then(m => m.CrudComponent) },
];
```

## Validación

```bash
test -f frontend-angular/package.json && test -f frontend-angular/angular.json && test -f frontend-angular/src/main.ts && test -f frontend-angular/src/app/app.component.ts && test -f frontend-angular/src/app/app.routes.ts && echo "OK"
```

## Reglas obligatorias

- **Sin sudo:** NO ejecutes comandos con `sudo`.
- **Commit siempre:** Al terminar, haz `git add` + `git commit` + `git push`.

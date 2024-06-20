import { Component } from '@angular/core';
import { AuthComponent } from './auth/auth.component';
import { ArticlesComponent } from './articles/articles.component';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
  standalone: true,
  imports: [AuthComponent, ArticlesComponent],
})
export class AppComponent {
  title = 'drupal-headless';
}


import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { provideHttpClient } from '@angular/common/http';

@Component({
  selector: 'app-articles',
  templateUrl: './articles.component.html',
  standalone: true,
})
export class ArticlesComponent {
  articles: any[] = [];

  constructor(private http: HttpClient) {}

  ngOnInit() {
    console.log('ArticlesComponent initialized');
    const token = localStorage.getItem('access_token');
    this.http.get('https://drupal-headless-backend.ddev.site/jsonapi/node/article', {
      headers: {
        Authorization: `Bearer ${token}`
      }
    }).subscribe((data: any) => {
      if (data.data) {
        this.articles = data.data;
      } else {
        console.log('No articles found.');
      }
    }, error => {
      console.error('Error fetching data:', error);
    });
  }
}


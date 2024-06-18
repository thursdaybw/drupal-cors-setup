import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-articles',
  templateUrl: './articles.component.html',
  styleUrls: ['./articles.component.css']
})
export class ArticlesComponent implements OnInit {
  articles: any[] = [];

  constructor(private http: HttpClient) {}

  ngOnInit() {
    console.log('ArticlesComponent initialized');
    const token = localStorage.getItem('access_token');
    this.http.get('https://YOUR_CORS_ENV.ddev.site/jsonapi/node/article', {
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

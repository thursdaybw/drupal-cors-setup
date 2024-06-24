import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private tokenSubject = new BehaviorSubject<string | null>(null);
  token$ = this.tokenSubject.asObservable();

  constructor(private http: HttpClient) {}

  login(username: string, password: string): Observable<string> {
    const url = 'https://drupal-headless-backend.ddev.site/oauth/token';
    //const url = 'https://%%CORS_ENV%%.ddev.site/oauth/token';
    const body = {
      grant_type: 'password',
      client_id: 'your-client-id',
      client_secret: 'your-client-secret',
      username: username,
      password: password
    };

    return this.http.post<any>(url, body).pipe(
      map(response => {
        if (response.access_token) {
          localStorage.setItem('token', response.access_token);
          this.tokenSubject.next(response.access_token);
          return 'Login successful!';
        } else {
          return 'Login failed!';
        }
      }),
      catchError(error => {
        console.error('Error during login:', error);
        return ['Login failed!'];
      })
    );
  }

  getArticles(): Observable<any> {
    const token = localStorage.getItem('token');
    if (token) {
      const url = 'https://drupal-headless-backend.ddev.site/jsonapi/node/article';
      return this.http.get<any>(url, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      }).pipe(
        map(response => response.data),
        catchError(error => {
          console.error('Error fetching articles:', error);
          return [];
        })
      );
    } else {
      return new Observable(observer => {
        observer.next([]);
        observer.complete();
      });
    }
  }

  logout(): void {
    localStorage.removeItem('token');
    this.tokenSubject.next(null);
  }
}


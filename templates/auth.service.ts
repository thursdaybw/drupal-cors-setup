import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private tokenSubject = new BehaviorSubject<string>(null);
  token$ = this.tokenSubject.asObservable();

  constructor(private http: HttpClient) {}

  login(username: string, password: string): Observable<any> {
    return this.http.post('https://%%CORS_ENV%%.ddev.site/oauth/token', {
      grant_type: 'password',
      client_id: 'your-client-id',
      client_secret: 'your-client-secret',
      username: username,
      password: password
    }).pipe(
      tap((data: any) => {
        if (data.access_token) {
          localStorage.setItem('token', data.access_token);
          this.tokenSubject.next(data.access_token);
        } else {
          this.tokenSubject.next(null);
        }
      }, error => {
        console.error('Error during login:', error);
        this.tokenSubject.next(null);
      })
    );
  }

  getArticles() {
    const token = localStorage.getItem('token');
    if (token) {
      return this.http.get('https://%%CORS_ENV%%.ddev.site/jsonapi/node/article', {
        headers: {
          'Authorization': 'Bearer ' + token
        }
      });
    }
  }

  logout() {
    localStorage.removeItem('token');
    this.tokenSubject.next(null);
  }
}


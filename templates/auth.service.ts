import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private tokenSubject = new BehaviorSubject<string | null>(null);
  token$ = this.tokenSubject.asObservable();

  constructor(private http: HttpClient) {}

  login(username: string, password: string): void {
    const url = 'https://drupal-headless-backend.ddev.site/oauth/token';
    //const url = 'https://%%CORS_ENV%%.ddev.site/oauth/token';
    const body = {
      grant_type: 'password',
      client_id: 'your-client-id',
      client_secret: 'your-client-secret',
      username: username,
      password: password
    };

    this.http.post(url, body).subscribe(
      (response: any) => {
        if (response.access_token) {
          localStorage.setItem('token', response.access_token);
          this.tokenSubject.next(response.access_token);
          console.log('Login successful!');
        } else {
          console.log('Login failed!');
        }
      },
      (error) => {
        console.error('Error during login:', error);
      }
    );
  }
}


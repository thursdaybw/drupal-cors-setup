
import { Component } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.css']
})
export class AuthComponent {
  username: string = '';
  password: string = '';
  message: string = '';

  constructor(private http: HttpClient, private router: Router) {}

  onSubmit() {
    this.http.post('https://YOUR_CORS_ENV.ddev.site/oauth/token', {
      grant_type: 'password',
      client_id: 'your-client-id',
      client_secret: 'your-client-secret',
      username: this.username,
      password: this.password
    }).subscribe((data: any) => {
      if (data.access_token) {
        localStorage.setItem('access_token', data.access_token);
        this.message = 'Login successful!';
        this.router.navigate(['/articles']);
      } else {
        this.message = 'Login failed!';
      }
    }, error => {
      console.error('Error during login:', error);
      this.message = 'Login failed!';
    });
  }
}

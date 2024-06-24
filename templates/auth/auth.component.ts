import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../auth.service';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  standalone: true,
  imports: [CommonModule, FormsModule]
})
export class AuthComponent {
  username: string = '';
  password: string = '';
  message: string = '';
  isLoggedIn: Observable<boolean>;

  constructor(private authService: AuthService) {
    this.isLoggedIn = this.authService.token$.pipe(
      map(token => !!token)
    );
  }

  ngOnInit() {
    console.log('AuthComponent initialized');
  }

  onSubmit() {
    this.authService.login(this.username, this.password).subscribe(() => {
      this.authService.token$.subscribe(token => {
        if (token) {
          this.message = 'Login successful!';
          console.log('Login successful, token:', token);
        } else {
          this.message = 'Login failed!';
          console.log('Login failed, no token received.');
        }
      });
    });
  }

  logout() {
    this.authService.logout();
    this.message = '';
  }
}


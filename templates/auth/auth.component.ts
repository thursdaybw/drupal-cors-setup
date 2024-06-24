import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.css'],
  standalone: true,
  imports: [CommonModule, HttpClientModule],
  providers: [AuthService]
})
export class AuthComponent {
  username: string = '';
  password: string = '';
  message: string = '';
  articles: any[] = [];
  isLoggedIn: boolean = false;

  constructor(private authService: AuthService) {}

  onSubmit(event: Event) {
    event.preventDefault();
    const form = event.target as HTMLFormElement;
    const formData = new FormData(form);
    const username = formData.get('username') as string;
    const password = formData.get('password') as string;
    this.authService.login(username, password).subscribe(
      message => {
        this.message = message;
        console.log(this.message);
        if (message === 'Login successful!') {
          this.isLoggedIn = true;
          this.authService.getArticles().subscribe(
            articles => {
              this.articles = articles;
              console.log('Articles:', articles);
            }
          );
        }
      }
    );
  }

  logout() {
    this.authService.logout();
    this.isLoggedIn = false;
    this.message = '';
    this.articles = [];
  }
}


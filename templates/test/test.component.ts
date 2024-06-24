import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-test',
  templateUrl: './test.component.html',
  standalone: true,
  imports: [CommonModule, HttpClientModule],
  providers: [AuthService]
})
export class TestComponent {
  username: string = '';
  password: string = '';
  message: string = '';

  constructor(private authService: AuthService) {}

  onSubmit(event: Event) {
    event.preventDefault();
    const form = event.target as HTMLFormElement;
    const formData = new FormData(form);
    const username = formData.get('username') as string;
    const password = formData.get('password') as string;
    this.authService.login(username, password);
    this.message = 'Login attempted';
  }
}


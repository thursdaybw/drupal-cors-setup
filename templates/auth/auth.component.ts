import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

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

  constructor() {}

  onSubmit() {
    // For now, just log the credentials and set a static message
    console.log(`Username: ${this.username}, Password: ${this.password}`);
    this.message = 'Login attempted';
  }
}


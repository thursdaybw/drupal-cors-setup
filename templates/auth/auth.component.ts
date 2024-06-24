import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms'; // Import FormsModule
import { AuthService } from '../auth.service';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  standalone: true,
  imports: [FormsModule]
})
export class AuthComponent {
  username: string = '';
  password: string = '';
  message: string = '';

  constructor(private authService: AuthService) {}

  ngOnInit() {
    console.log('AuthComponent initialized');
  }

  onSubmit() {
  this.authService.login(this.username, this.password).subscribe(() => {
    this.authService.token$.subscribe(token => {
      if (token) {
        this.message = 'Login successful!';
      } else {
        this.message = 'Login failed!';
      }
    });
  });
}

}

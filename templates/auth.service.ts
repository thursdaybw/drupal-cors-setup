import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  constructor(private http: HttpClient) {}

  login(username: string, password: string): void {
    console.log(`Username: ${username}, Password: ${password}`);
    // Placeholder for actual login logic
  }
}


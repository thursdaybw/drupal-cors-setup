import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpClientModule } from '@angular/common/http';

@Component({
  selector: 'app-test',
  templateUrl: './test.component.html',
  standalone: true,
  imports: [CommonModule, HttpClientModule]
})
export class TestComponent {
  constructor(private http: HttpClient) {}
}


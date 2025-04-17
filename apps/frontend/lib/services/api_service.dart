import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<http.Response> login(String email, String password) {
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: {'email': email, 'password': password},
    );
  }

  static Future<http.Response> register(String name, String email, String password) {
    return http.post(
      Uri.parse('$baseUrl/auth/register'),
      body: {'name': name, 'email': email, 'password': password},
    );
  }

  static Future<http.Response> fetchExpenses() {
    return http.get(Uri.parse('$baseUrl/expenses'));
  }
}
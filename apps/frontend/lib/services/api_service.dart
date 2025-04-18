import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  static const storage = FlutterSecureStorage();

  static Future<http.Response> login(String email, String password) async {
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  static Future<http.Response> register(
      String name, String email, String password) async {
    return http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
  }

  static Future<http.Response> fetchExpenses() async {
    String? token = await storage.read(key: 'token');
    return http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<http.Response> addExpense(
      String title, double amount, String date, String? category) async {
    String? token = await storage.read(key: 'token');
    return http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'date': date,
        if (category != null) 'category': category,
      }),
    );
  }

  static Future<http.Response> deleteExpense(String id) async {
    String? token = await storage.read(key: 'token');
    return http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<void> logout() async {
    await storage.delete(key: 'token');
  }
}

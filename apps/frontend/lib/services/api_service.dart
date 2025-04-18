import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Use different URLs depending on platform:
  // - For Android emulator: 10.0.2.2 points to host machine's localhost
  // - For iOS simulator: 127.0.0.1 points to host machine's localhost
  // - Keep localhost for web platforms
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000'; // Web platform
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000'; // Android emulator -> host's localhost
      } else if (Platform.isIOS) {
        return 'http://127.0.0.1:3000'; // iOS simulator -> host's localhost
      }
    } catch (e) {
      // Platform API not available, fallback to localhost
    }

    return 'http://localhost:3000'; // Fallback
  }

  static const storage = FlutterSecureStorage();

  // Add a connection test method to help debug connectivity issues
  static Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'baseUrl': baseUrl,
      'isConnected': false,
      'statusCode': null,
      'error': null,
    };

    try {
      // Try the health endpoint
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/health'),
            )
            .timeout(const Duration(seconds: 5));

        result['isConnected'] =
            response.statusCode >= 200 && response.statusCode < 300;
        result['statusCode'] = response.statusCode;
        result['response'] = response.body;

        // If we got here, connection is working
        if (result['isConnected']) {
          return result;
        }
      } catch (e) {
        // Health endpoint failed, try another endpoint
        result['healthError'] = e.toString();
      }

      // Try auth endpoint as fallback
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/auth'),
            )
            .timeout(const Duration(seconds: 5));

        // Even a 404 here means the server is responding
        result['isConnected'] = true;
        result['statusCode'] = response.statusCode;
      } catch (e) {
        // Try root endpoint as last resort
        try {
          final response = await http
              .get(
                Uri.parse(baseUrl),
              )
              .timeout(const Duration(seconds: 5));

          // If we get any response, the server is reachable
          result['isConnected'] = true;
          result['rootEndpointStatus'] = response.statusCode;
        } catch (e) {
          result['error'] = 'Server unreachable: ${e.toString()}';
        }
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

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

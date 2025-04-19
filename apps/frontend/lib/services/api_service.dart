import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Add a debug flag to easily enable/disable verbose logging
  static const bool _verboseLogging = true;

  static void _log(String message) {
    if (_verboseLogging) {
      debugPrint("API_SERVICE: $message");
    }
  }

  // Use different URLs depending on platform:
  // - For Android emulator: 10.0.2.2 points to host machine's localhost
  // - For iOS simulator: 127.0.0.1 points to host machine's localhost
  // - Keep localhost for web platforms
  // - External URLs (like ngrok) are used as-is
  static String get baseUrl {
    // First check if dotenv is correctly loaded
    _log("Checking .env configuration...");
    final envVars = dotenv.env;
    _log("Available env vars: ${envVars.keys.join(', ')}");

    // Get URL from environment or use fallback
    final configuredUrl = dotenv.env['BACKEND_URL'];
    if (configuredUrl == null) {
      _log("WARNING: BACKEND_URL not found in .env file!");
      // Fall back to the previous hardcoded URL
      return 'http://localhost:8080';
    }

    _log("Original URL from .env: $configuredUrl");

    // Parse the URL to handle it properly
    Uri uri;
    try {
      uri = Uri.parse(configuredUrl);
    } catch (e) {
      _log("ERROR parsing URL: $e");
      return 'http://localhost:8080';
    }

    // If it's not a localhost URL, use it as-is
    if (uri.host != 'localhost' && uri.host != '127.0.0.1') {
      _log("Using external URL: $configuredUrl");
      return configuredUrl;
    }

    if (kIsWeb) {
      _log("Using URL for web platform: $configuredUrl");
      return configuredUrl; // Web platform
    }

    String resultUrl = configuredUrl;
    try {
      if (Platform.isAndroid) {
        // Replace localhost or 127.0.0.1 with 10.0.2.2 for Android
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          resultUrl = uri.replace(host: '10.0.2.2').toString();
          _log("Using Android URL: $resultUrl");
        }
      } else if (Platform.isIOS) {
        // Replace localhost with 127.0.0.1 for iOS if needed
        if (uri.host == 'localhost') {
          resultUrl = uri.replace(host: '127.0.0.1').toString();
          _log("Using iOS URL: $resultUrl");
        }
      }
      return resultUrl;
    } catch (e) {
      // Platform API not available, fallback
      _log("Platform error: $e, using default");
    }

    _log("Fallback URL: $configuredUrl");
    return configuredUrl; // Fallback
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
              headers: _getHeaders(), // Use common headers
            )
            .timeout(const Duration(seconds: 5));

        result['isConnected'] =
            response.statusCode >= 200 && response.statusCode < 300;
        result['statusCode'] = response.statusCode;
        result['response'] = response.body;
        result['contentType'] = response.headers['content-type'];

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
              headers: _getHeaders(), // Use common headers
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
                headers: _getHeaders(), // Use common headers
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

  // Helper method to get common headers for API requests
  static Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Skip ngrok warning page
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Test method to verify dotenv loading and URL configuration
  static Map<String, dynamic> debugEnvConfig() {
    final result = <String, dynamic>{};

    // Check if dotenv is loaded
    result['dotenvLoaded'] = dotenv.env.isNotEmpty;
    result['envVarCount'] = dotenv.env.length;
    result['envVarKeys'] = dotenv.env.keys.toList();
    result['backendUrl'] = dotenv.env['BACKEND_URL'];
    result['resolvedBaseUrl'] = baseUrl;
    result['runningOnWeb'] = kIsWeb;

    try {
      result['platform'] = Platform.operatingSystem;
    } catch (e) {
      result['platform'] = 'unknown (likely web)';
    }

    return result;
  }

  static Future<http.Response> login(String email, String password) async {
    return http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  static Future<http.Response> register(
      String name, String email, String password) async {
    return http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
  }

  static Future<http.Response> fetchExpenses() async {
    String? token = await storage.read(key: 'token');
    _log(
        "Fetching expenses from: $baseUrl/expenses with token: ${token != null ? 'available' : 'missing'}");

    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: _getHeaders(token),
    );

    _log("Expenses response status: ${response.statusCode}");
    _log("Expenses response content type: ${response.headers['content-type']}");
    if (response.statusCode != 200) {
      _log(
          "Error response: ${response.body.substring(0, min(200, response.body.length))}...");
    }

    return response;
  }

  // Use min function for string truncation
  static int min(int a, int b) => a < b ? a : b;

  static Future<http.Response> addExpense(
      String title, double amount, String date, String? category,
      [Uint8List? imageBytes]) async {
    String? token = await storage.read(key: 'token');

    _log(
        "addExpense called with ${imageBytes != null ? '${imageBytes.length} bytes image' : 'no image'}");

    // Create expense payload
    final Map<String, dynamic> payload = {
      'title': title,
      'amount': amount,
      'date': date,
      if (category != null) 'category': category,
    };

    // If image bytes are provided, convert to base64
    if (imageBytes != null) {
      try {
        _log("Converting ${imageBytes.length} bytes to base64");
        final String base64Image = base64Encode(imageBytes);
        _log("Base64 image length: ${base64Image.length}");

        // Add to payload
        payload['receiptImage'] = base64Image;
      } catch (e) {
        _log("Error encoding image: $e");
      }
    }

    _log("Sending expense payload with fields: ${payload.keys.join(', ')}");
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: _getHeaders(token),
      body: jsonEncode(payload),
    );

    _log("Response status: ${response.statusCode}");
    try {
      _log("Response body: ${response.body}");
    } catch (e) {
      _log("Could not log response body: $e");
    }

    return response;
  }

  static Future<http.Response> deleteExpense(String id) async {
    String? token = await storage.read(key: 'token');
    return http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: _getHeaders(token),
    );
  }

  static Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  /// Upload an image file to the backend and return the URL or identifier
  static Future<String?> uploadImage(File imageFile) async {
    try {
      String? token = await storage.read(key: 'token');

      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/expenses/upload-image'),
      );

      // Add authorization header and ngrok header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'true',
      });

      // Add the file to the request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      request.files.add(multipartFile);

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        // Get the response body
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        // Return the image URL or identifier from the response
        return jsonResponse[
            'imageUrl']; // Adjust based on your backend response
      } else {
        debugPrint('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}

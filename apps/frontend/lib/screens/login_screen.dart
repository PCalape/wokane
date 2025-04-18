import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:expense_tracker/widgets/input_field.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'registration_screen.dart';
import 'expense_tracker_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _connectionStatus;
  bool _connectionTestInProgress = false;
  bool _forceLogin = false;

  @override
  void initState() {
    super.initState();
    // Check connection when the screen first loads
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (_connectionTestInProgress) return;

    setState(() {
      _connectionTestInProgress = true;
    });

    try {
      final status = await ApiService.testConnection();
      if (mounted) {
        setState(() {
          _connectionStatus = status;
          _connectionTestInProgress = false;
          if (status['isConnected'] == true) {
            _errorMessage = null;
          }
        });
      }

      debugPrint("Login: Connection status: $status");
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = {
            'isConnected': false,
            'error': e.toString(),
            'baseUrl': ApiService.baseUrl,
          };
          _connectionTestInProgress = false;
        });
      }
      debugPrint("Login: Connection check error: ${e.toString()}");
    }
  }

  Future<void> _login() async {
    // Clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("Login: Attempting login...");
      debugPrint(
          "Login: Email=${_emailController.text}, Password=${_passwordController.text.replaceAll(RegExp(r'.'), '*')}");

      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your network or server status.');
        },
      );

      // Log the raw response for debugging
      debugPrint("Login: Response status code: ${response.statusCode}");
      debugPrint("Login: Raw response body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("Login: Success with status 200!");

        try {
          // Parse response and store token
          final responseData = json.decode(response.body);
          debugPrint("Login: Parsed JSON data: $responseData");

          if (responseData.containsKey('access_token')) {
            final token = responseData['access_token'];
            debugPrint(
                "Login: Got token: ${token.toString().substring(0, min(10, token.toString().length))}...");

            // Store the token
            await storage.write(key: 'token', value: token);
            debugPrint("Login: Token stored successfully");

            if (!mounted) return;
            // Navigate to expense tracker screen with a slight delay
            // This helps ensure the token is properly stored before navigation
            Future.delayed(const Duration(milliseconds: 100), () {
              debugPrint("Login: Navigating to Wokane screen");
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpenseTrackerScreen()),
              );
            });
          } else {
            debugPrint("Login: Response missing access_token field");
            setState(() {
              _errorMessage = 'Invalid response from server: missing token';
            });
          }
        } catch (e) {
          debugPrint("Login: Error parsing response JSON: $e");
          setState(() {
            _errorMessage = 'Error parsing server response: $e';
          });
        }
      } else {
        debugPrint("Login: Failed with status ${response.statusCode}");
        String errorMessage = 'Login failed with status ${response.statusCode}';

        try {
          final responseData = json.decode(response.body);
          debugPrint("Login: Error response data: $responseData");
          errorMessage = responseData['message'] ?? errorMessage;
        } catch (e) {
          debugPrint("Login: Could not parse error response: $e");
        }

        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      debugPrint("Login: Error during login: ${e.toString()}");
      setState(() {
        _errorMessage = e is TimeoutException
            ? 'Connection timed out. Please check if the server is running.'
            : 'Connection error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to show a debug/development login in case of connection issues
  void _toggleForceLogin() {
    setState(() {
      _forceLogin = !_forceLogin;
      if (_forceLogin) {
        _errorMessage =
            "⚠️ Warning: Force login mode enabled. This bypasses connection checks and may not work properly.";
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          // Add a debug button that's only visible in debug mode
          if (kDebugMode)
            IconButton(
              icon: Icon(_forceLogin ? Icons.warning_amber : Icons.bug_report),
              onPressed: _toggleForceLogin,
              tooltip: 'Toggle force login (debug)',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputField(
              label: 'Email',
              controller: _emailController,
            ),
            InputField(
              label: 'Password',
              obscureText: true,
              controller: _passwordController,
            ),
            const SizedBox(height: 20),

            // Connection status indicator
            if (_connectionTestInProgress && !_forceLogin)
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Checking connection...",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),

            if (_connectionStatus != null &&
                _connectionStatus!['isConnected'] == false &&
                !_forceLogin)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Column(
                  children: [
                    const Text(
                      "Cannot connect to the server",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Server URL: ${_connectionStatus!['baseUrl']}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                    if (_connectionStatus!['error'] != null)
                      Text(
                        "Error: ${_connectionStatus!['error']}",
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ElevatedButton.icon(
                      onPressed: _checkConnection,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _forceLogin ? Colors.orange : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: 'Login',
                    onPressed: (_connectionStatus != null &&
                                _connectionStatus!['isConnected'] == true) ||
                            _forceLogin
                        ? _login
                        : _checkConnection,
                  ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegistrationScreen()),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),

            // Add server details at the bottom of the screen in debug mode
            if (kDebugMode)
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Server: ${ApiService.baseUrl}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text(
                            _connectionStatus != null
                                ? "Status: ${_connectionStatus!['isConnected'] == true ? 'Connected' : 'Disconnected'}"
                                : "Status: Unknown",
                            style: TextStyle(
                                fontSize: 12,
                                color: _connectionStatus != null &&
                                        _connectionStatus!['isConnected'] ==
                                            true
                                    ? Colors.green
                                    : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

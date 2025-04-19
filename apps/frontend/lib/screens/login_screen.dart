import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'registration_screen.dart';
import 'expense_tracker_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _connectionStatus;
  bool _connectionTestInProgress = false;
  bool _forceLogin = false;
  bool _obscurePassword = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    // Set up animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
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

      // Accept both 200 and 201 status codes as success
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Login: Success with status ${response.statusCode}!");

        try {
          // Parse response and store token
          final responseData = json.decode(response.body);
          debugPrint("Login: Parsed JSON data: $responseData");

          // Check for both 'access_token' and 'accessToken' fields to handle API variations
          String? token;
          if (responseData.containsKey('access_token')) {
            token = responseData['access_token'];
          } else if (responseData.containsKey('accessToken')) {
            token = responseData['accessToken'];
          }

          if (token != null) {
            debugPrint(
                "Login: Got token: ${token.toString().substring(0, min(10, token.toString().length))}...");

            // Store the token
            await storage.write(key: 'token', value: token);
            debugPrint("Login: Token stored successfully");

            if (!mounted) return;
            // Navigate to expense tracker screen with a slight delay
            Future.delayed(const Duration(milliseconds: 100), () {
              debugPrint("Login: Navigating to expense tracker screen");
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExpenseTrackerScreen()),
              );
            });
          } else {
            debugPrint("Login: Response missing token field");
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Logo and welcome header
                  Center(
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // App name
                        Text(
                          'WOKANE',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Text(
                          'Expense Tracking Simplified',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Welcome text
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue tracking your expenses',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email field with icon
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      prefixIcon:
                          Icon(Icons.email_outlined, color: Colors.grey[600]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password field with toggle visibility
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: Colors.grey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connection status indicator and error message
                  if (_connectionTestInProgress && !_forceLogin)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
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
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_connectionStatus != null &&
                      _connectionStatus!['isConnected'] == false &&
                      !_forceLogin)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Column(
                          children: [
                            const Text(
                              "Cannot connect to the server",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Server URL: ${_connectionStatus!['baseUrl']}",
                              style: const TextStyle(color: Colors.orange),
                            ),
                            if (_connectionStatus!['error'] != null)
                              Text(
                                "Error: ${_connectionStatus!['error']}",
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ElevatedButton.icon(
                              onPressed: _checkConnection,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Try Again"),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _forceLogin ? Colors.orange : Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Login button
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: (_connectionStatus != null &&
                                      _connectionStatus!['isConnected'] ==
                                          true) ||
                                  _forceLogin
                              ? _login
                              : _checkConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  const SizedBox(height: 24),

                  // Register account link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Server status display for debug mode
                  if (kDebugMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        children: [
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Developer Options",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _forceLogin
                                      ? Icons.warning_amber
                                      : Icons.bug_report,
                                  color: _forceLogin
                                      ? Colors.orange
                                      : Colors.grey[600],
                                ),
                                onPressed: _toggleForceLogin,
                                tooltip: 'Toggle force login (debug)',
                              ),
                            ],
                          ),
                          Text(
                            "Server: ${ApiService.baseUrl}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

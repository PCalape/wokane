import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:expense_tracker/screens/login_screen.dart';
import 'package:expense_tracker/screens/expense_tracker_screen.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final storage = const FlutterSecureStorage();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isCheckingAuth = true;
  bool _isConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Set up animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // First check connection, then authentication status
    _checkConnectionAndAuthentication();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionAndAuthentication() async {
    // Add a slight delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Test connection to backend
      final connectionStatus = await ApiService.testConnection();
      _isConnected = connectionStatus['isConnected'] ?? false;

      if (!_isConnected) {
        setState(() {
          _errorMessage =
              'Cannot connect to server. Please check your connection.';
          _isCheckingAuth = false;
        });
        return;
      }

      // Check authentication status
      final token = await storage.read(key: 'token');

      // Delay to ensure the animation completes
      if (_animationController.status != AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      // Navigate based on authentication status
      if (token != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ExpenseTrackerScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error during startup: ${e.toString()}';
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with fade-in animation
            FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Wokane',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator or error message
            if (_isCheckingAuth)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text('Getting things ready...'),
                ],
              )
            else if (_errorMessage != null)
              Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isCheckingAuth = true;
                        _errorMessage = null;
                      });
                      _checkConnectionAndAuthentication();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

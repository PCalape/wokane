import 'dart:convert';
import 'package:expense_tracker/widgets/custom_button.dart';
import 'package:expense_tracker/widgets/input_field.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'expense_tracker_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (response.statusCode == 201) {
        // Registration successful, now login
        final loginResponse = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );

        if (loginResponse.statusCode == 200) {
          // Parse response and store token
          final responseData = json.decode(loginResponse.body);
          await storage.write(
              key: 'token', value: responseData['access_token']);

          if (!mounted) return;
          // Navigate to expense tracker screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ExpenseTrackerScreen()),
          );
        } else {
          // Registration worked but login failed
          setState(() {
            _errorMessage = 'Registration successful. Please login.';
          });
          if (!mounted) return;
          Navigator.pop(context);
        }
      } else {
        final responseData = json.decode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputField(
              label: 'Name',
              controller: _nameController,
            ),
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _isLoading
                ? const CircularProgressIndicator()
                : CustomButton(
                    text: 'Register',
                    onPressed: _register,
                  ),
          ],
        ),
      ),
    );
  }
}

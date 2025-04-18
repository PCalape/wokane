import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/expense_tracker_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wokane',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      // Set SplashScreen as the initial route
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/expenses': (context) => const ExpenseTrackerScreen(),
      },
    );
  }
}

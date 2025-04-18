import 'dart:convert';
import 'dart:async';
import 'package:expense_tracker/widgets/expense_item.dart';
import 'package:expense_tracker/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_screen.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadExpenses();
  }

  Future<void> _checkTokenAndLoadExpenses() async {
    // First check if we have a valid token
    try {
      final token = await storage.read(key: 'token');
      debugPrint(
          "ExpenseTracker: Token check - ${token != null ? 'Token exists' : 'No token found'}");
      if (token == null) {
        debugPrint("ExpenseTracker: No token found, redirecting to login");
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }

      // If token exists, continue loading expenses
      _loadExpenses();
    } catch (e) {
      debugPrint("ExpenseTracker: Error checking token: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = "Error checking authentication: $e";
      });
    }
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("ExpenseTracker: Loading expenses...");

      // Add timeout to prevent indefinite loading
      final response = await ApiService.fetchExpenses().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your network or server status.');
        },
      );

      debugPrint("ExpenseTracker: Response status ${response.statusCode}");
      debugPrint("ExpenseTracker: Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> expensesJson = json.decode(response.body);
        debugPrint("ExpenseTracker: Loaded ${expensesJson.length} expenses");

        setState(() {
          _expenses = expensesJson
              .map((expense) => expense as Map<String, dynamic>)
              .toList();
        });
      } else if (response.statusCode == 401) {
        debugPrint("ExpenseTracker: Unauthorized (401) - token may be invalid");
        // Token expired or invalid, redirect to login
        await storage.delete(key: 'token');
        if (!mounted) return;

        // Show a message briefly before redirecting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      } else {
        String errorBody = "No additional details";
        try {
          errorBody = json.decode(response.body).toString();
        } catch (_) {}

        debugPrint("ExpenseTracker: Error response: $errorBody");
        setState(() {
          _errorMessage =
              'Failed to load expenses: Status ${response.statusCode}\n$errorBody';
        });
      }
    } catch (e) {
      debugPrint("ExpenseTracker: Error loading expenses: ${e.toString()}");
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

  Future<void> _addExpense() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final TextEditingController categoryController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Expense'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      dateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Title and amount are required')),
                  );
                  return;
                }

                try {
                  final double amount = double.parse(amountController.text);
                  final response = await ApiService.addExpense(
                    titleController.text,
                    amount,
                    dateController.text,
                    categoryController.text.isNotEmpty
                        ? categoryController.text
                        : null,
                  );

                  if (response.statusCode == 201) {
                    Navigator.of(context).pop();
                    _loadExpenses();
                  } else {
                    final responseData = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(responseData['message'] ??
                              'Failed to add expense')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid amount format')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wokane'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading expenses...', style: TextStyle(fontSize: 16)),
                  Text('If loading persists, check server connection',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Error',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadExpenses,
                        icon: Icon(Icons.refresh),
                        label: Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _expenses.isEmpty
                  ? const Center(
                      child: Text('No expenses found. Add your first expense!'))
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return ExpenseItem(
                          title: expense['title'] ?? 'Untitled',
                          amount: '\$${expense['amount'] ?? 0}',
                          date: expense['date'] ?? 'No date',
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}

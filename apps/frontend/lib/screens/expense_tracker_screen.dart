import 'package:flutter/material.dart';

class ExpenseTrackerScreen extends StatelessWidget {
  const ExpenseTrackerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: ListView.builder(
        itemCount: 10, // Replace with dynamic data
        itemBuilder: (context, index) {
          return const ExpenseItem(
            title: 'Expense Title',
            amount: '
$100',
            date: '2025-04-17',
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add expense logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
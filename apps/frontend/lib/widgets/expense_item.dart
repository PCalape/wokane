import 'package:flutter/material.dart';

class ExpenseItem extends StatelessWidget {
  final String title;
  final String amount;
  final String date;

  const ExpenseItem({Key? key, required this.title, required this.amount, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<Transaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = DatabaseHelper().getTransactions();
  }

  void _refreshTransactions() {
    setState(() {
      _transactions = DatabaseHelper().getTransactions();
    });
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    return category;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: RefreshIndicator(
         onRefresh: () async {
          _refreshTransactions();
        },
        child: FutureBuilder<List<Transaction>>(
          future: _transactions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final transaction = snapshot.data![index];
                  final isIncome = transaction.type == 'Income';
                  final color = isIncome ? Colors.green : Colors.red;
                  
                  return ListTile(
                    leading: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: color,
                    ),
                    title: Text(transaction.description, style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text(_getLocalizedCategory(context, transaction.category), style: Theme.of(context).textTheme.bodySmall),
                    trailing: Text(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

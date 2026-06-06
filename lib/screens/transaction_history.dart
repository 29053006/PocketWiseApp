import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<my_models.Transaction>> _transactions;
  CurrencyProvider? _currencyProvider;

  @override
  void initState() {
    super.initState();
    _transactions = DatabaseHelper().getTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newCurrencyProvider = Provider.of<CurrencyProvider>(context);
    if (newCurrencyProvider != _currencyProvider) {
      _currencyProvider?.removeListener(_refreshTransactions);
      _currencyProvider = newCurrencyProvider;
      _currencyProvider?.addListener(_refreshTransactions);
    }
  }

  @override
  void dispose() {
    _currencyProvider?.removeListener(_refreshTransactions);
    super.dispose();
  }

  void _refreshTransactions() {
    if (mounted) {
      setState(() {
        _transactions = DatabaseHelper().getTransactions();
      });
    }
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currency = currencyProvider.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshTransactions();
        },
        child: FutureBuilder<List<my_models.Transaction>>(
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
                  final convertedAmount = convertCurrency(transaction.amount, currency);
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
                      formatCurrency(convertedAmount, currency),
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

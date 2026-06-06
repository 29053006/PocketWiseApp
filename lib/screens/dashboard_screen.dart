import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

// Data model for the dashboard
class DashboardData {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<my_models.Transaction> recentTransactions;

  DashboardData({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.recentTransactions,
  });
}

// Top-level function to perform calculations. This can be run in a separate isolate.
DashboardData _calculateDashboardData(List<my_models.Transaction> transactions) {
  developer.log('Starting calculation in isolate...');
  final double totalIncome = transactions.where((t) => t.type == 'Income').fold(0, (sum, t) => sum + t.amount);
  final double totalExpense = transactions.where((t) => t.type == 'Expense').fold(0, (sum, t) => sum + t.amount);
  final double balance = totalIncome - totalExpense;

  // Sort transactions to get the most recent ones
  transactions.sort((a, b) => b.date.compareTo(a.date));
  final recent = transactions.take(5).toList();

  developer.log('Calculation in isolate finished.');
  return DashboardData(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    balance: balance,
    recentTransactions: recent,
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<DashboardData> _dashboardData;
  CurrencyProvider? _currencyProvider;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<DashboardData> _loadDashboardData() async {
    final transactions = await DatabaseHelper().getTransactions();
    // Use compute to run calculations in a separate isolate to prevent UI freezing.
    return compute(_calculateDashboardData, transactions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    // Refresh the dashboard when the currency changes
    final newCurrencyProvider = Provider.of<CurrencyProvider>(context);
    if (newCurrencyProvider != _currencyProvider) {
      _currencyProvider?.removeListener(_refreshDashboard);
      _currencyProvider = newCurrencyProvider;
      _currencyProvider?.addListener(_refreshDashboard);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _currencyProvider?.removeListener(_refreshDashboard);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  void _refreshDashboard() {
    if (mounted) {
      setState(() {
        _dashboardData = _loadDashboardData();
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
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDashboard();
        },
        child: FutureBuilder<DashboardData>(
          future: _dashboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.recentTransactions.isEmpty) {
              // Use a lightweight placeholder instead of a GIF
              return const Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Add a new transaction to get started.', style: TextStyle(color: Colors.grey)),
                ],
              ));
            } else {
              final data = snapshot.data!;
              final convertedBalance = convertCurrency(data.balance, currency);
              final convertedIncome = convertCurrency(data.totalIncome, currency);
              final convertedExpense = convertCurrency(data.totalExpense, currency);

              return Column(
                children: [
                  _buildSummaryCard(context, convertedBalance, convertedIncome, convertedExpense, currency),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.recentTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = data.recentTransactions[index];
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
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, double balance, double totalIncome, double totalExpense, String currency) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              formatCurrency(balance, currency),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeExpense(context, 'Income', totalIncome, Colors.green, currency),
                _buildIncomeExpense(context, 'Expense', totalExpense, Colors.red, currency),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpense(BuildContext context, String title, double amount, Color color, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          formatCurrency(amount, currency),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

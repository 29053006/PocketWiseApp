import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/transaction_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<List<Transaction>> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = DatabaseHelper().getTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // This method is called when the top route has been popped off,
    // and the current route is now visible.
    _refreshTransactions();
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
        title: const Text('Dashboard'),
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
              final transactions = snapshot.data!;
              double totalIncome = transactions.where((t) => t.type == 'Income').fold(0, (sum, t) => sum + t.amount);
              double totalExpense = transactions.where((t) => t.type == 'Expense').fold(0, (sum, t) => sum + t.amount);
              double balance = totalIncome - totalExpense;

              return Column(
                children: [
                  _buildSummaryCard(context, balance, totalIncome, totalExpense),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: transactions.length > 5 ? 5 : transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
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

  Widget _buildSummaryCard(BuildContext context, double balance, double totalIncome, double totalExpense) {
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
              '\$${balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeExpense(context, 'Income', totalIncome, Colors.green),
                _buildIncomeExpense(context, 'Expense', totalExpense, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpense(BuildContext context, String title, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

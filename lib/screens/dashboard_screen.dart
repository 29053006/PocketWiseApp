import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/screens/transaction_history.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<Map<String, dynamic>> _dashboardData;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _dashboardData = _getDashboardData();
  }

  Future<Map<String, dynamic>> _getDashboardData() async {
    final transactions = await dbHelper.getTransactions();
    double totalIncome = 0;
    double totalExpenses = 0;
    double monthlyExpenses = 0;
    final now = DateTime.now();

    for (var t in transactions) {
      if (t.type == 'Income') {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
        if (t.date.month == now.month && t.date.year == now.year) {
          monthlyExpenses += t.amount;
        }
      }
    }

    const double monthlyBudget = 2000.0; // Example budget
    final budgetUsedPercentage =
        (monthlyBudget > 0 ? monthlyExpenses / monthlyBudget : 0.0)
            .clamp(0.0, 1.0);

    transactions.sort((a, b) => b.date.compareTo(a.date));
    return {
      'totalBalance': totalIncome - totalExpenses,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'recentTransactions': transactions.take(5).toList(),
      'monthlyBudget': monthlyBudget,
      'monthlyExpenses': monthlyExpenses,
      'budgetUsedPercentage': budgetUsedPercentage,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh data when returning to this screen
    setState(() {
      _dashboardData = _getDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary, size: 30)),
        title: Text('PocketWise',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              backgroundImage:
                  NetworkImage('https://i.pravatar.cc/150?img=3'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildBalanceCard(
                    context, data['totalBalance'], currencyProvider.currency),
                const SizedBox(height: 20),
                _buildIncomeExpenseRow(context, data['totalIncome'],
                    data['totalExpenses'], currencyProvider.currency),
                const SizedBox(height: 20),
                _buildBudgetHealthCard(
                    context,
                    data['monthlyExpenses'],
                    data['monthlyBudget'],
                    data['budgetUsedPercentage'],
                    currencyProvider.currency),
                const SizedBox(height: 30),
                _buildRecentTransactions(
                    context, data['recentTransactions'], currencyProvider.currency),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, double balance, String currency) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withAlpha(204)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            formatCurrency(balance, currency),
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(
      BuildContext context, double income, double expenses, String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildIncomeExpenseCard(
              context, 'Income', income, currency, Icons.arrow_downward_rounded, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIncomeExpenseCard(context, 'Expenses', expenses, currency,
              Icons.arrow_upward_rounded, Colors.red),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseCard(BuildContext context, String title,
      double amount, String currency, IconData icon, Color iconColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(formatCurrency(amount, currency),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetHealthCard(BuildContext context, double monthlyExpenses,
      double monthlyBudget, double budgetUsedPercentage, String currency) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Health',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                TextButton(onPressed: () {}, child: const Text('View Plans')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Monthly Spending',
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                Expanded(
                    flex: 2,
                    child: Text(
                        '${(budgetUsedPercentage * 100).toStringAsFixed(0)}% used',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budgetUsedPercentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatCurrency(monthlyExpenses, currency)} of ${formatCurrency(monthlyBudget, currency)}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, List<my_models.Transaction> transactions, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Transactions',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TransactionHistoryScreen()),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final isIncome = transaction.type == 'Income';
            final color = isIncome
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green)
                : (Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _getIconForCategory(transaction.category),
                ),
                title: Text(transaction.description,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface)),
                subtitle: Text(DateFormat.yMMMd().format(transaction.date),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                trailing: Text(
                  '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount, currency)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 16),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Icon _getIconForCategory(String category) {
    Color iconColor;
    switch (category) {
      case 'Groceries':
        iconColor = Colors.orange.shade300;
        break;
      case 'Salary':
        iconColor = Colors.green.shade300;
        break;
      case 'Dining':
        iconColor = Colors.red.shade300;
        break;
      case 'Transport':
        iconColor = Colors.blue.shade300;
        break;
      case 'Netflix':
        iconColor = Colors.deepPurple.shade300;
        break;
      default:
        iconColor = Theme.of(context).colorScheme.secondary;
    }

    switch (category) {
      case 'Groceries':
        return Icon(Icons.shopping_bag_outlined, color: iconColor);
      case 'Salary':
        return Icon(Icons.account_balance_wallet_outlined, color: iconColor);
      case 'Dining':
        return Icon(Icons.local_cafe_outlined, color: iconColor);
      case 'Transport':
        return Icon(Icons.directions_bus_outlined, color: iconColor);
      case 'Netflix':
        return Icon(Icons.live_tv_outlined, color: iconColor);
      default:
        return Icon(Icons.category_outlined, color: iconColor);
    }
  }
}

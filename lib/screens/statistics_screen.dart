import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<List<Transaction>> _transactions;
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
        title: const Text('Statistics'),
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
              return _buildCharts(context, snapshot.data!, currency);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCharts(BuildContext context, List<Transaction> transactions, String currency) {
    final expenseData = _getCategoryData(transactions, 'Expense', currency);
    final incomeData = _getCategoryData(transactions, 'Income', currency);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text("Expense by Category", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(
          height: 250,
          child: PieChart(_buildPieChartData(context, expenseData, currency)),
        ),
        const SizedBox(height: 24),
        Text("Income by Category", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(
          height: 250,
          child: PieChart(_buildPieChartData(context, incomeData, currency)),
        ),
      ],
    );
  }

  Map<String, double> _getCategoryData(List<Transaction> transactions, String type, String currency) {
    final Map<String, double> categoryMap = {};
    for (var t in transactions) {
      if (t.type == type) {
        final convertedAmount = convertCurrency(t.amount, currency);
        categoryMap[t.category] = (categoryMap[t.category] ?? 0) + convertedAmount;
      }
    }
    return categoryMap;
  }

  PieChartData _buildPieChartData(
      BuildContext context, Map<String, double> data, String currency) {
    final colorScheme = Theme.of(context).colorScheme;
    int colorIndex = 0;
    final chartColors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    return PieChartData(
      sectionsSpace: 4,
      centerSpaceRadius: 40,
      sections: data.entries.map((entry) {
        final color = chartColors[colorIndex % chartColors.length];
        colorIndex++;

        return PieChartSectionData(
          color: color,
          value: entry.value,
          title:
              '${_getLocalizedCategory(context, entry.key)}\n${formatCurrency(entry.value, currency)}',
          radius: 80,
          titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
        );
      }).toList(),
    );
  }
}

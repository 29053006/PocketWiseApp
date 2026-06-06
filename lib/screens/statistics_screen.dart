import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<List<my_models.Transaction>> _transactionsFuture;
  String _selectedFilter = 'This Month';

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _loadTransactions();
  }

  void _refreshData() {
    setState(() {
      _transactionsFuture = _loadTransactions();
    });
  }

  Future<List<my_models.Transaction>> _loadTransactions() async {
    return await DatabaseHelper().getTransactions();
  }

  List<my_models.Transaction> _filterTransactions(
      List<my_models.Transaction> transactions) {
    final now = DateTime.now();
    if (_selectedFilter == 'This Month') {
      return transactions
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    } else if (_selectedFilter == 'Last Month') {
      final lastMonth = now.month - 1 == 0 ? 12 : now.month - 1;
      final year = now.month - 1 == 0 ? now.year - 1 : now.year;
      return transactions
          .where((t) => t.date.year == year && t.date.month == lastMonth)
          .toList();
    } else if (_selectedFilter == 'This Year') {
      return transactions.where((t) => t.date.year == now.year).toList();
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SvgPicture.asset(
                'assets/images/logo.svg',
                key: const ValueKey('logo_image'),
                height: 24,
                placeholderBuilder: (context) => const Icon(Icons.business_center, size: 24),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PocketWise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {
              // Handle notifications action
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: FutureBuilder<List<my_models.Transaction>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No transactions yet.'));
            } else {
              final filteredTransactions = _filterTransactions(snapshot.data!);
              return _buildStatisticsBody(filteredTransactions, snapshot.data!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsBody(List<my_models.Transaction> filteredTransactions,
      List<my_models.Transaction> allTransactions) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildTimeFilter(),
        const SizedBox(height: 24),
        if (filteredTransactions.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("No transaction data for this period."),
          ))
        else ...[
          _buildExpensesByCategoryCard(filteredTransactions),
          const SizedBox(height: 24),
          _buildWeeklySpendCard(filteredTransactions),
          const SizedBox(height: 24),
          _buildSmartTipCard(allTransactions),
        ]
      ],
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          dropdownColor: Theme.of(context).colorScheme.surfaceVariant,
          items: ['This Month', 'Last Month', 'This Year'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedFilter = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildExpensesByCategoryCard(
      List<my_models.Transaction> transactions) {
    final currency = Provider.of<CurrencyProvider>(context).currency;
    final expenses = transactions.where((t) => t.type == 'Expense').toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expenses by Category',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 24),
            if (expenses.isEmpty)
              const SizedBox(
                  height: 200,
                  child: Center(
                      child: Text("No expense data for this period.")))
            else
              _buildPieChart(expenses, currency),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<my_models.Transaction> expenses, String currency) {
    final totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final Map<String, double> categoryMap = {};
    for (var t in expenses) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final List<Color> colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.primary.withOpacity(0.7),
      colorScheme.secondary.withOpacity(0.7),
    ];
    int colorIndex = 0;

    final List<PieChartSectionData> sections = [];
    categoryMap.forEach((category, amount) {
      final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                  sections: sections, centerSpaceRadius: 60, sectionsSpace: 4)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('EXPENSES',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, letterSpacing: 1.2)),
                  Text(formatCurrency(totalExpense, currency),
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        ..._buildLegend(categoryMap, totalExpense, colors, currency),
      ],
    );
  }

  List<Widget> _buildLegend(Map<String, double> categoryMap,
      double totalExpense, List<Color> colors, String currency) {
    int colorIndex = 0;
    final sortedEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final color = colors[colorIndex++ % colors.length];
      final percentage = totalExpense > 0
          ? (entry.value / totalExpense * 100).toStringAsFixed(0)
          : "0";
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 12),
            Text(entry.key, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            SizedBox(
                width: 90,
                child: Text(
                  formatCurrency(entry.value, currency),
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.right,
                )),
            const SizedBox(width: 16),
            SizedBox(
                width: 40,
                child: Text('$percentage%',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          ],
        ),
      );
    }).toList();
  }

  Map<int, double> _calculateWeeklySpending(
      List<my_models.Transaction> transactions) {
    final weeklySpending = <int, double>{1: 0, 2: 0, 3: 0, 4: 0};
    final now = DateTime.now();

    final expenses = transactions.where((t) => t.type == 'Expense');

    for (final transaction in expenses) {
      if (transaction.date.year == now.year &&
          transaction.date.month == now.month) {
        final dayOfMonth = transaction.date.day;
        final weekOfMonth = (dayOfMonth / 7).ceil();

        if (weekOfMonth >= 1 && weekOfMonth <= 4) {
          weeklySpending[weekOfMonth] =
              (weeklySpending[weekOfMonth] ?? 0) + transaction.amount;
        }
      }
    }
    return weeklySpending;
  }

  Widget _buildWeeklySpendCard(List<my_models.Transaction> transactions) {
    final weeklyData = _calculateWeeklySpending(transactions);
    final totalWeeklySpend = weeklyData.values.fold(0.0, (a, b) => a + b);
    final averageWeeklySpend = weeklyData.values.where((v) => v > 0).isEmpty
        ? 0
        : totalWeeklySpend / weeklyData.values.where((v) => v > 0).length;
    final currency = Provider.of<CurrencyProvider>(context).currency;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Spend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            Text(
                'Average ${formatCurrency(averageWeeklySpend.toDouble(), currency)} / week',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _getBarGroups(weeklyData),
                  maxY: weeklyData.values.isEmpty ||
                          weeklyData.values.every((v) => v == 0)
                      ? 100
                      : weeklyData.values.reduce(max).toDouble() * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: (double value, TitleMeta meta) {
          String text = '';
          switch (value.toInt()) {
            case 0:
              text = 'W1';
              break;
            case 1:
              text = 'W2';
              break;
            case 2:
              text = 'W3';
              break;
            case 3:
              text = 'W4';
              break;
          }
          return SideTitleWidget(
            child: Text(text,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            meta: meta,
            space: 4,
          );
        },
      );

  List<BarChartGroupData> _getBarGroups(Map<int, double> weeklyData) {
    return List.generate(4, (index) {
      final week = index + 1;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[week] ?? 0.0,
            color: Theme.of(context).colorScheme.primary,
            width: 22,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          )
        ],
      );
    });
  }

  Widget _buildSmartTipCard(List<my_models.Transaction> allTransactions) {
    final expenses = allTransactions.where((t) => t.type == 'Expense').toList();
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find category with highest spending
    final Map<String, double> categoryMap = {};
    for (var t in expenses) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highestCategory = sortedCategories.first.key;
    final highestAmount = sortedCategories.first.value;
    final currency = Provider.of<CurrencyProvider>(context).currency;

    final tip =
        "You've spent the most on $highestCategory (${formatCurrency(highestAmount, currency)}). Consider looking for ways to reduce this expense.";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.onTertiaryContainer, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Tip',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late Future<List<my_models.Transaction>> _transactionsFuture;
  List<my_models.Transaction> _transactions = [];
  List<my_models.Transaction> _filteredTransactions = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _loadTransactions();
    _searchController.addListener(_filterTransactions);
  }

  Future<List<my_models.Transaction>> _loadTransactions() async {
    final transactions = await DatabaseHelper().getTransactions();
    // Sort transactions by date in descending order
    transactions.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _transactions = transactions;
      _applyFilter();
    });
    return transactions;
  }

  void _filterTransactions() {
    _applyFilter();
  }

  void _applyFilter() {
    var filtered = _transactions.where((t) {
      final query = _searchController.text.toLowerCase();
      return t.description.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query);
    }).toList();

    if (_selectedFilter != 'All') {
      filtered = filtered.where((t) => t.type == _selectedFilter).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTransaction(int id, LanguageProvider lang) async {
    await DatabaseHelper().deleteTransaction(id);
    _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('transaction_deleted'))),
      );
    }
  }

  Map<String, List<my_models.Transaction>> _groupTransactionsByDate(
      List<my_models.Transaction> transactions, LanguageProvider lang) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String getGroupKey(DateTime date) {
      final transactionDate = DateTime(date.year, date.month, date.day);
      if (transactionDate == today) {
        return lang.translate('today').toUpperCase();
      } else if (transactionDate == yesterday) {
        return lang.translate('yesterday').toUpperCase();
      } else {
        return DateFormat('MMM d').format(date).toUpperCase();
      }
    }

    return groupBy(transactions, (my_models.Transaction t) => getGroupKey(t.date));
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final currency = currencyProvider.currency;
    final groupedTransactions = _groupTransactionsByDate(_filteredTransactions, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(lang),
          _buildFilterChips(lang),
          Expanded(
            child: FutureBuilder<List<my_models.Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_transactions.isEmpty) {
                  return Center(child: Text(lang.translate('no_transactions')));
                } else {
                  return RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      itemCount: groupedTransactions.keys.length,
                      itemBuilder: (context, index) {
                        final dateKey = groupedTransactions.keys.elementAt(index);
                        final transactions = groupedTransactions[dateKey]!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                                child: Text(
                                  dateKey,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...transactions.map((transaction) {
                                return _buildTransactionItem(
                                    transaction, currency, lang);
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: lang.translate('search_transactions'),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(LanguageProvider lang) {
    final filterLabels = {
      'All': lang.translate('all'),
      'Income': lang.translate('income'),
      'Expense': lang.translate('expenses'),
      'Bills': lang.translate('bills'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['All', 'Income', 'Expense', 'Bills']
              .map((label) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(filterLabels[label]!),
                      selected: _selectedFilter == label,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? label : 'All';
                      _applyFilter();
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: _selectedFilter == label
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      my_models.Transaction transaction, String currency, LanguageProvider lang) {
    final isIncome = transaction.type == 'Income';
    final colorScheme = Theme.of(context).colorScheme;
    final color = isIncome ? colorScheme.primary : colorScheme.error;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              _deleteTransaction(transaction.id!, lang);
            },
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            icon: Icons.delete,
            label: lang.translate('delete'),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getCategoryColor(transaction.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _getIconForCategory(transaction.category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lang.translate(transaction.category.toLowerCase())} • ${DateFormat.jm().format(transaction.date)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
      case 'Dining':
      case 'Groceries':
        return Icon(Icons.fastfood, color: Colors.orange.shade300);
      case 'Transport':
        return Icon(Icons.directions_car, color: Colors.blue.shade300);
      case 'Home':
        return Icon(Icons.home, color: Colors.brown.shade300);
      case 'Shopping':
        return Icon(Icons.shopping_bag, color: Colors.pink.shade300);
      case 'Health':
        return Icon(Icons.health_and_safety, color: Colors.red.shade300);
      case 'Movies':
      case 'Netflix':
        return Icon(Icons.movie, color: Colors.deepPurple.shade300);
      case 'Salary':
        return Icon(Icons.work, color: Colors.green.shade300);
      case 'Bonus':
        return Icon(Icons.card_giftcard, color: Colors.amber.shade300);
      case 'Investment':
        return Icon(Icons.trending_up, color: Colors.teal.shade300);
      case 'Gift':
        return Icon(Icons.cake, color: Colors.purple.shade300);
      case 'Other':
        return Icon(Icons.more_horiz, color: Colors.grey.shade500);
      default:
        return Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.secondary);
    }
  }

  Color _getCategoryColor(String category) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (category) {
      case 'Food':
      case 'Dining':
      case 'Groceries':
        return colorScheme.secondary;
      case 'Salary':
        return Colors.green.shade300;
      case 'Transport':
        return colorScheme.primary.withValues(alpha: 0.8);
      case 'Netflix':
        return colorScheme.secondary.withValues(alpha: 0.8);
      case 'Other':
        return colorScheme.outline;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}

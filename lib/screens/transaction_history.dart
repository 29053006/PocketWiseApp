import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
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
      _filteredTransactions = transactions;
    });
    return transactions;
  }

  void _filterTransactions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTransactions = _transactions.where((t) {
        final descriptionMatch = t.description.toLowerCase().contains(query);
        final categoryMatch = t.category.toLowerCase().contains(query);
        return descriptionMatch || categoryMatch;
      }).toList();
      _applyFilter();
    });
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

  Future<void> _deleteTransaction(int id) async {
    await DatabaseHelper().deleteTransaction(id);
    _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  Map<String, List<my_models.Transaction>> _groupTransactionsByDate(
      List<my_models.Transaction> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String getGroupKey(DateTime date) {
      final transactionDate = DateTime(date.year, date.month, date.day);
      if (transactionDate == today) {
        return 'TODAY';
      } else if (transactionDate == yesterday) {
        return 'YESTERDAY';
      } else {
        return DateFormat('MMM d').format(date).toUpperCase();
      }
    }

    return groupBy(transactions, (my_models.Transaction t) => getGroupKey(t.date));
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final currency = currencyProvider.currency;
    final groupedTransactions = _groupTransactionsByDate(_filteredTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<my_models.Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (groupedTransactions.isEmpty) {
                  return const Center(child: Text('No transactions yet.'));
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
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...transactions.map((transaction) {
                                return _buildTransactionItem(
                                    transaction, currency);
                              }).toList(),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['All', 'Income', 'Expense', 'Bills']
            .map((label) => ChoiceChip(
                  label: Text(label),
                  selected: _selectedFilter == label,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? label : 'All';
                      _applyFilter();
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                      color: _selectedFilter == label
                          ? Colors.white
                          : Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTransactionItem(
      my_models.Transaction transaction, String currency) {
    final isIncome = transaction.type == 'Income';
    final color = isIncome ? Colors.green : Colors.red;

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              _deleteTransaction(transaction.id!);
            },
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
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
                  color: _getCategoryColor(transaction.category).withOpacity(0.1),
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
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.category} • ${DateFormat.jm().format(transaction.date)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
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
    Color color = _getCategoryColor(category);
    switch (category) {
      case 'Groceries':
        return Icon(Icons.shopping_bag_outlined, color: color);
      case 'Salary':
        return Icon(Icons.account_balance_wallet_outlined, color: color);
      case 'Dining':
        return Icon(Icons.local_cafe_outlined, color: color);
      case 'Transport':
        return Icon(Icons.directions_bus_outlined, color: color);
      case 'Netflix':
        return Icon(Icons.live_tv_outlined, color: color);
      default:
        return Icon(Icons.category_outlined, color: color);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Groceries':
        return Colors.orange;
      case 'Salary':
        return Colors.green;
      case 'Dining':
        return Colors.red;
      case 'Transport':
        return Colors.blue;
      case 'Netflix':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

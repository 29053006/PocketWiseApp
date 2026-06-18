import 'package:flutter/material.dart';
import 'package:myapp/data/database_helper.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/transaction_model.dart' as my_models;
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/screens/budget_screen.dart';
import 'package:myapp/screens/transaction_history.dart';
import 'package:myapp/screens/notification_screen.dart';
import 'package:myapp/util/currency_util.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:myapp/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<Map<String, dynamic>> _dashboardData;
  Future<User?>? _futureUser;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _dashboardData = _getDashboardData();
    _futureUser = dbHelper.getUser();

    // Verificar notificación de bienvenida después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSystemNotifications();
    });
  }

  Future<void> _checkSystemNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Solicitar permisos de sistema para Android 13+
    await notifProvider.requestPermissions();

    // 1. Notificación de Bienvenida
    final bool hasShowedWelcome = prefs.getBool('welcome_notification_sent') ?? false;
    if (!hasShowedWelcome) {
      if (!mounted) return;
      notifProvider.addNotification(
        titleKey: 'welcome_notif_title',
        messageKey: 'welcome_notif_msg',
      );
      await prefs.setBool('welcome_notification_sent', true);
    }

    // 2. Recordatorio Diario (si no hay registros hoy y no se ha procesado hoy)
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final lastReminderDate = prefs.getString('last_daily_reminder_date');

    if (lastReminderDate != todayStr) {
      final transactions = await dbHelper.getTransactions();
      final hasToday = transactions.any((t) => 
          t.date.day == now.day && t.date.month == now.month && t.date.year == now.year);
      
      if (!hasToday) {
        if (!mounted) return;
        notifProvider.addNotification(
          titleKey: 'reminder_notif_title',
          messageKey: 'reminder_notif_msg',
        );
      }
      // Guardamos que ya se revisó/envió el recordatorio para el día de hoy
      await prefs.setString('last_daily_reminder_date', todayStr);
    }
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

    final double monthlyBudget = await dbHelper.getMonthlyBudget();
    final budgetUsedPercentage =
        (monthlyBudget > 0 ? monthlyExpenses / monthlyBudget : 0.0)
            .clamp(0.0, 1.0);

    // 3. Notificación de Presupuesto > 90%
    if (budgetUsedPercentage >= 0.9) {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final lastBudgetAlertDate = prefs.getString('last_budget_alert_date');

      if (lastBudgetAlertDate != todayStr) {
        Future.microtask(() {
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false).addNotification(
              titleKey: 'budget_alert_title',
              messageKey: 'budget_alert_msg',
            );
          }
        });
        await prefs.setString('last_budget_alert_date', todayStr);
      }
    }

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
      routeObserver.subscribe(this, modalRoute);
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
      _futureUser = dbHelper.getUser();
    });
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final String base64Image = base64Encode(bytes);

      final currentUser = await dbHelper.getUser();
      if (currentUser != null) {
        final updatedUser = User(
          id: currentUser.id,
          name: currentUser.name,
          avatar: base64Image,
        );
        await dbHelper.updateUser(updatedUser);
        
        if (!mounted) return;
        setState(() {
          _futureUser = dbHelper.getUser();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary, size: 30)),
        title: FutureBuilder<User?>(
          future: _futureUser,
          builder: (context, snapshot) {
            final name = snapshot.data?.name ?? 'PocketWise';
            return Text(
              name == 'PocketWise' ? name : 'Hi, $name',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Badge(
                label: Text(notifProvider.unreadCount.toString()),
                isLabelVisible: notifProvider.unreadCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          FutureBuilder<User?>(
            future: _futureUser,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final imageBytes = (user?.avatar != null) ? base64Decode(user!.avatar!) : null;
              return GestureDetector(
                onTap: _pickProfileImage,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                  child: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null ? Icon(Icons.person, color: colorScheme.primary) : null,
                  ),
                ),
              );
            },
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
            return Center(child: Text(lang.translate('no_data_period')));
          } else {
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildBalanceCard(
                    context, data['totalBalance'], currencyProvider.currency, lang),
                const SizedBox(height: 20),
                _buildIncomeExpenseRow(context, data['totalIncome'],
                    data['totalExpenses'], currencyProvider.currency, lang),
                const SizedBox(height: 20),
                _buildBudgetHealthCard(
                    context,
                    data['monthlyExpenses'],
                    data['monthlyBudget'],
                    data['budgetUsedPercentage'],
                    currencyProvider.currency,
                    lang),
                const SizedBox(height: 30),
                _buildRecentTransactions(
                    context, data['recentTransactions'], currencyProvider.currency, lang),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, double balance, String currency, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.translate('total_balance'),
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatCurrency(balance, currency),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow(
      BuildContext context, double income, double expenses, String currency, LanguageProvider lang) {
    return Row(
      children: [
        Expanded(
          child: _buildIncomeExpenseCard(
              context, lang.translate('income'), income, currency, Icons.arrow_downward_rounded, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildIncomeExpenseCard(context, lang.translate('expenses'), expenses, currency,
              Icons.arrow_upward_rounded, Colors.red),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseCard(BuildContext context, String title,
      double amount, String currency, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatCurrency(amount, currency),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetHealthCard(BuildContext context, double monthlyExpenses,
      double monthlyBudget, double budgetUsedPercentage, String currency, LanguageProvider lang) {
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
                Expanded(
                  child: Text(
                    lang.translate('budget_health'),
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BudgetScreen()),
                  ).then((_) => didPopNext()), 
                  child: Text(lang.translate('manage_budget'), 
                    style: const TextStyle(fontSize: 13))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(lang.translate('monthly_spending'),
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                Expanded(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${(budgetUsedPercentage * 100).toStringAsFixed(0)}${lang.translate('used_perc')}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold)),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budgetUsedPercentage,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${formatCurrency(monthlyExpenses, currency)} ${lang.translate('of')} ${formatCurrency(monthlyBudget, currency)}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, List<my_models.Transaction> transactions, String currency, LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lang.translate('recent_transactions'),
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
              child: Text(lang.translate('see_all')),
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _getIconForCategory(transaction.category),
                ),
                title: Text(
                  transaction.description,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(DateFormat.yMMMd().format(transaction.date),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                trailing: Text(
                  '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount, currency)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 15),
                ),
              ),
            );
          },
        ),
      ],
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
      default:
        return Icon(Icons.category_outlined, color: Theme.of(context).colorScheme.secondary);
    }
  }
}

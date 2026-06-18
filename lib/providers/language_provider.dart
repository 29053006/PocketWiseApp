import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // Valor por defecto seguro
  static const String _languageKey = 'language_code';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLanguageCode = prefs.getString(_languageKey);
    
    if (savedLanguageCode != null) {
      if (_locale.languageCode != savedLanguageCode) {
        _locale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } else {
      // Si no hay guardado, detectar el del sistema
      final systemCode = PlatformDispatcher.instance.locale.languageCode;
      _locale = Locale(systemCode == 'es' ? 'es' : 'en');
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home': 'Home',
      'history': 'History',
      'stats': 'Stats',
      'search_transactions': 'Search transactions...',
      'settings': 'Settings',
      'total_balance': 'Total Balance',
      'income': 'Income',
      'expenses': 'Expenses',
      'all': 'All',
      'recent_transactions': 'Recent Transactions',
      'see_all': 'See All',
      'budget_health': 'Budget Health',
      'new_transaction': 'New Transaction',
      'amount_label': 'AMOUNT',
      'select_category': 'Select Category',
      'date': 'Date',
      'note': 'Note (Optional)',
      'save_transaction': 'Save Transaction',
      'this_month': 'This Month',
      'last_month': 'Last Month',
      'this_year': 'This Year',
      'expenses_by_category': 'Expenses by Category',
      'manage_budget': 'Manage Budget',
      'data_local_secure': 'Your data is stored locally and securely.',
      'welcome_title': 'Welcome to\nPocketWise',
      'smart_tracking_sub': 'Smart tracking for a better\nfinancial future.',
      'whats_your_name': "WHAT'S YOUR NAME?",
      'name_hint': 'e.g. Alex Smith',
      'name_error': 'Please let us know how to call you',
      'get_started': 'Get Started',
      'view_plans': 'View Plans',
      'monthly_spending': 'Monthly Spending',
      'used_perc': '% used',
      'of': 'of',
      'profile': 'Profile',
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'use_system_theme': 'Use System Theme',
      'app_color': 'App Color',
      'currency': 'Currency',
      'display_currency': 'Display Currency',
      'app_language': 'App Language',
      'database': 'Database',
      'clear_database': 'Clear Database',
      'clear_db_sub': 'Delete all transactions from the database.',
      'edit_name': 'Edit Name',
      'edit_name_hint': 'Enter your name',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm_deletion': 'Confirm Deletion',
      'clear_db_confirm_msg': 'Are you sure you want to delete all transactions? This action cannot be undone.',
      'delete': 'Delete',
      'db_cleared_msg': 'All transactions have been deleted.',
      'no_transactions': 'No transactions yet.',
      'transaction_deleted': 'Transaction deleted',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'bills': 'Bills',
      'no_data_period': 'No transaction data for this period.',
      'weekly_spend': 'Weekly Spend',
      'average': 'Average',
      'week': 'week',
      'smart_tip_title': 'Smart Tip',
      'smart_tip_msg': "You've spent the most on ",
      'smart_tip_msg_end': ". Consider looking for ways to reduce this expense.",
      'enter_valid_amount': 'Please enter a valid amount',
      'enter_amount_error': 'Please enter an amount',
      'budget_info_msg_start': 'Saving this will put you at ',
      'budget_info_msg_end': '% of your monthly food budget.',
      'what_was_this_for': 'What was this for?',
      'where_did_this_come_from': 'Where did this come from?',
      'no_user_data': 'No user data',
      // Categories
      'cat_food': 'Food', 'cat_transport': 'Transport', 'cat_home': 'Home', 'cat_shopping': 'Shopping',
      'cat_health': 'Health', 'cat_movies': 'Movies', 'cat_salary': 'Salary', 'cat_bonus': 'Bonus',
      'cat_investment': 'Investment', 'cat_gift': 'Gift', 'cat_other': 'Other', 'cat_dining': 'Dining',
      'cat_netflix': 'Netflix', 'cat_groceries': 'Groceries',
      // Notifications
      'welcome_notif_title': 'Welcome to PocketWise!',
      'welcome_notif_msg': 'We are glad to have you here. Start tracking your finances today!',
      'budget_alert_title': 'Budget Alert',
      'budget_alert_msg': 'Careful! You have used more than 90% of your monthly budget.',
      'reminder_notif_title': 'Daily Reminder',
      'reminder_notif_msg': 'Don\'t forget to record your transactions for today to keep your balance updated.',
      'notifications': 'Notifications',
      'no_notifications': 'No new notifications',
      'notification_deleted': 'Notification deleted',
    },
    'es': {
      'home': 'Inicio',
      'history': 'Historial',
      'stats': 'Estadísticas',
      'search_transactions': 'Buscar transacciones...',
      'settings': 'Ajustes',
      'total_balance': 'Saldo Total',
      'income': 'Ingresos',
      'expenses': 'Gastos',
      'all': 'Todos',
      'recent_transactions': 'Transacciones Recientes',
      'see_all': 'Ver Todo',
      'budget_health': 'Salud del Presupuesto',
      'new_transaction': 'Nueva Transacción',
      'amount_label': 'MONTO',
      'select_category': 'Seleccionar Categoría',
      'date': 'Fecha',
      'note': 'Nota (Opcional)',
      'save_transaction': 'Guardar Transacción',
      'this_month': 'Este Mes',
      'last_month': 'Mes Pasado',
      'this_year': 'Este Año',
      'expenses_by_category': 'Gastos por Categoría',
      'manage_budget': 'Gestionar Presupuesto',
      'data_local_secure': 'Tus datos se guardan localmente y de forma segura.',
      'welcome_title': 'Bienvenido a\nPocketWise',
      'smart_tracking_sub': 'Seguimiento inteligente para un mejor futuro financiero.',
      'whats_your_name': "¿CÓMO TE LLAMAS?",
      'name_hint': 'ej. Alex Smith',
      'name_error': 'Por favor, dinos cómo llamarte',
      'get_started': 'Comenzar',
      'view_plans': 'Ver Planes',
      'monthly_spending': 'Gasto Mensual',
      'used_perc': '% usado',
      'of': 'de',
      'profile': 'Perfil',
      'appearance': 'Apariencia',
      'dark_mode': 'Modo Oscuro',
      'use_system_theme': 'Usar Tema del Sistema',
      'app_color': 'Color de la App',
      'currency': 'Moneda',
      'display_currency': 'Moneda de Visualización',
      'app_language': 'Idioma de la App',
      'database': 'Base de Datos',
      'clear_database': 'Borrar Base de Datos',
      'clear_db_sub': 'Eliminar todas las transacciones de la base de datos.',
      'edit_name': 'Editar Nombre',
      'edit_name_hint': 'Introduce tu nombre',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'confirm_deletion': 'Confirmar Eliminación',
      'clear_db_confirm_msg': '¿Estás seguro de que quieres borrar todas las transacciones? Esta acción no se puede deshacer.',
      'delete': 'Eliminar',
      'db_cleared_msg': 'Todas las transacciones han sido eliminadas.',
      'no_transactions': 'Aún no hay transacciones.',
      'transaction_deleted': 'Transacción eliminada',
      'today': 'Hoy',
      'yesterday': 'Ayer',
      'bills': 'Facturas',
      'no_data_period': 'No hay datos de transacciones para este período.',
      'weekly_spend': 'Gasto Semanal',
      'average': 'Promedio',
      'week': 'semana',
      'smart_tip_title': 'Consejo Inteligente',
      'smart_tip_msg': "Has gastado más en ",
      'smart_tip_msg_end': ". Considera buscar formas de reducir este gasto.",
      'enter_valid_amount': 'Por favor, introduce un monto válido',
      'enter_amount_error': 'Por favor, introduce un monto',
      'budget_info_msg_start': 'Guardar esto te pondrá al ',
      'budget_info_msg_end': '% de tu presupuesto mensual de comida.',
      'what_was_this_for': '¿Para qué fue esto?',
      'where_did_this_come_from': '¿De dónde vino esto?',
      'no_user_data': 'Sin datos de usuario',
      // Categories
      'cat_food': 'Comida', 'cat_transport': 'Transporte', 'cat_home': 'Hogar', 'cat_shopping': 'Compras',
      'cat_health': 'Salud', 'cat_movies': 'Cine', 'cat_salary': 'Salario', 'cat_bonus': 'Bono',
      'cat_investment': 'Inversión', 'cat_gift': 'Regalo', 'cat_other': 'Otro', 'cat_dining': 'Cenas',
      'cat_netflix': 'Netflix', 'cat_groceries': 'Supermercado',
      // Notificaciones
      'welcome_notif_title': '¡Bienvenido a PocketWise!',
      'welcome_notif_msg': 'Nos alegra tenerte aquí. ¡Empieza a tomar el control de tus finanzas hoy!',
      'budget_alert_title': 'Alerta de Presupuesto',
      'budget_alert_msg': '¡Cuidado! Has consumido más del 90% de tu presupuesto mensual.',
      'reminder_notif_title': 'Recordatorio Diario',
      'reminder_notif_msg': 'No olvides registrar tus movimientos de hoy para mantener tu saldo al día.',
      'notifications': 'Notificaciones',
      'no_notifications': 'No hay notificaciones nuevas',
      'notification_deleted': 'Notificación eliminada',
      'Hi': 'Hola',
    },
  };

  String translate(String key) {
    return _localizedValues[_locale.languageCode]?[key] ?? key;
  }
}
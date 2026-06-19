import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/screens/add_transaction.dart';
import 'package:myapp/screens/dashboard_screen.dart';
import 'package:myapp/screens/settings_screen.dart';
import 'package:myapp/screens/statistics_screen.dart';
import 'package:myapp/screens/transaction_history.dart';
import 'package:myapp/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform;
import 'dart:developer' as developer;

// Route Observer
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  developer.log('App starting...');
  WidgetsFlutterBinding.ensureInitialized();

  final startTime = DateTime.now();
  // --- Inicialización de FlutterLocalNotificationsPlugin ---
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  try {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Usamos el icono por defecto para evitar errores

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        developer.log('Notification tapped: ${notificationResponse.payload}');
      },
    );
  } catch (e) {
    developer.log('Error initializing notifications: $e');
    // La app continuará aunque las notificaciones fallen
  }
  // --- Fin de la inicialización de FlutterLocalNotificationsPlugin ---

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else if (kIsWeb) {
    // Use sqflite_common_ffi_web for web
    databaseFactory = databaseFactoryFfiWeb;
  }

  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;

  developer.log('Initialization complete in ${DateTime.now().difference(startTime).inMilliseconds} ms');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider(
          flutterLocalNotificationsPlugin,
          Provider.of<LanguageProvider>(context, listen: false))),
      ],
      child: MyApp(isFirstTime: isFirstTime),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _color = const Color(0xFF3661F2);
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';

  ThemeMode get themeMode => _themeMode;
  Color get color => _color;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    
    final colorValue = prefs.getInt(_colorKey) ?? const Color(0xFF3661F2).toARGB32();
    _color = Color(colorValue);
    
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    notifyListeners();
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    notifyListeners();
  }

  Future<void> setColor(Color color) async {
    _color = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context);

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        final lightTheme = _buildTheme(themeProvider.color, Brightness.light);
        final darkTheme = _buildTheme(themeProvider.color, Brightness.dark);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PocketWise',
          theme: lightTheme,
          darkTheme: darkTheme,
          locale: languageProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          themeMode: themeProvider.themeMode,
          navigatorObservers: [routeObserver],
          initialRoute: isFirstTime ? '/welcome' : '/main',
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/main': (context) => const MainScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionHistoryScreen(),
    const SizedBox(), // Placeholder for Add Transaction
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // The \"Add\" button in the center
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddTransactionScreen(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.widgets_outlined, lang.translate('home'), 0),
            _buildNavItem(Icons.history, lang.translate('history'), 1),
            const SizedBox(width: 40), // The space for the FAB
            _buildNavItem(Icons.pie_chart_outline, lang.translate('stats'), 3),
            _buildNavItem(Icons.settings_outlined, lang.translate('settings'), 4),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
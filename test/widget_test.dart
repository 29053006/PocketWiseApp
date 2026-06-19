import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/currency_provider.dart';
import 'package:myapp/providers/language_provider.dart';
import 'package:myapp/providers/notification_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Widget createTestableWidget(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => CurrencyProvider()),
      ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ChangeNotifierProvider(create: (context) => NotificationProvider(
        FlutterLocalNotificationsPlugin(),
        Provider.of<LanguageProvider>(context, listen: false))),
    ],
    child: child,
  );
}

void main() {
  testWidgets('Renders main screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Set isFirstTime to false to simulate a returning user
    await tester.pumpWidget(createTestableWidget(const MyApp(isFirstTime: false)));

    // Verify that the main screen is rendered
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Renders welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame for a first-time user.
    await tester.pumpWidget(createTestableWidget(const MyApp(isFirstTime: true)));

    // Verify that the welcome screen is rendered
    expect(find.text("WHAT'S YOUR NAME?"), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

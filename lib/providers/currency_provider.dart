import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = 'USD';
  static const String _currencyKey = 'currency';

  String get currency => _currency;

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_currencyKey) ?? 'USD';
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    if (newCurrency == _currency) return;

    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, newCurrency);
    notifyListeners();
  }
}

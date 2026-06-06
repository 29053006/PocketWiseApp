import 'package:intl/intl.dart';

const double usdToCopRate = 4000.0;

/// Converts the given amount from USD to the target currency.
/// Assumes the base currency is USD.
double convertCurrency(double amount, String targetCurrency) {
  if (targetCurrency == 'COP') {
    return amount * usdToCopRate;
  }
  return amount; // It's already in USD
}

/// Formats the given amount into a currency string, assuming it's already
/// in the correct target currency value.
String formatCurrency(double amount, String currency) {
  final format = NumberFormat.currency(
    symbol: currency == 'COP' ? 'COP ' : '\$',
    decimalDigits: 2,
  );
  return format.format(amount);
}

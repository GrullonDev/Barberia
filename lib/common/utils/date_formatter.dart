import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(final DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  static String formatTime(final DateTime date) =>
      DateFormat('HH:mm').format(date);

  static String formatDateTime(final DateTime date) =>
      DateFormat('dd/MM/yyyy HH:mm').format(date);

  static String formatCurrency(final double amount) =>
      NumberFormat.currency(symbol: r'$').format(amount);
}

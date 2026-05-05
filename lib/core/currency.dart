import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(symbol: '\$');
final DateFormat _dateFormatter = DateFormat('MMM d, y • h:mm a');

String formatCurrency(double value) => _currencyFormatter.format(value);

String formatDateTime(DateTime value) => _dateFormatter.format(value);

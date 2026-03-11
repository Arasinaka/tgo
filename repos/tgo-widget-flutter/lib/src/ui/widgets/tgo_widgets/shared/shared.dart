import 'package:intl/intl.dart';

export 'widget_card.dart';
export 'status_badge.dart';
export 'info_row.dart';
export 'action_buttons.dart';

String formatPrice(double? price, [String currency = '¥']) {
  if (price == null) return '${currency}0.00';
  final formatter = NumberFormat("0.00");
  return '$currency${formatter.format(price)}';
}


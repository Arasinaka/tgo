import 'package:flutter/material.dart';
import './models/widget_types.dart';
import './shared/shared.dart';
import 'order_widget.dart';
import 'logistics_widget.dart';
import 'product_widget.dart';
import 'product_list_widget.dart';
import 'price_comparison_widget.dart';
import 'unknown_widget.dart';

class WidgetRenderer extends StatelessWidget {
  final WidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const WidgetRenderer({
    super.key,
    required this.data,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (data is OrderWidgetData) {
      return OrderWidget(
        data: data as OrderWidgetData,
        onSendMessage: onSendMessage,
        onAction: onAction,
        onCopySuccess: onCopySuccess,
      );
    } else if (data is LogisticsWidgetData) {
      return LogisticsWidget(
        data: data as LogisticsWidgetData,
        onSendMessage: onSendMessage,
        onAction: onAction,
        onCopySuccess: onCopySuccess,
      );
    } else if (data is ProductWidgetData) {
      return ProductWidget(
        data: data as ProductWidgetData,
        onSendMessage: onSendMessage,
        onAction: onAction,
        onCopySuccess: onCopySuccess,
      );
    } else if (data is ProductListWidgetData) {
      return ProductListWidget(
        data: data as ProductListWidgetData,
        onSendMessage: onSendMessage,
        onAction: onAction,
        onCopySuccess: onCopySuccess,
      );
    } else if (data is PriceComparisonWidgetData) {
      return PriceComparisonWidget(
        data: data as PriceComparisonWidgetData,
        onSendMessage: onSendMessage,
        onAction: onAction,
        onCopySuccess: onCopySuccess,
      );
    } else {
      return UnknownWidget(
        data: data,
        onAction: onAction,
      );
    }
  }
}


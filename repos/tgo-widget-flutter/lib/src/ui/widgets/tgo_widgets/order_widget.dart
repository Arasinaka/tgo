import 'package:flutter/material.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class OrderWidget extends StatelessWidget {
  final OrderWidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const OrderWidget({
    super.key,
    required this.data,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);
    final statusStyle = _getStatusStyle(data.status);
    final currency = data.currency ?? '¥';

    return WidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          WidgetHeader(
            icon: Icon(Icons.inventory_2_outlined, color: theme.primaryColor, size: 20),
            iconBgColor: theme.primaryColor.withOpacity(0.1),
            subtitle: 'Order ID',
            title: data.orderId,
            badge: StatusBadge(
              text: data.statusText ?? data.status.name,
              bgColor: statusStyle.bgColor,
              textColor: statusStyle.textColor,
              icon: Icon(statusStyle.icon, size: 14, color: statusStyle.textColor),
            ),
          ),

          const SizedBox(height: 16),

          // Product list
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.borderPrimary),
                bottom: BorderSide(color: theme.borderPrimary),
              ),
            ),
            child: Column(
              children: data.items.map((item) => _buildOrderItem(context, item, theme, currency)).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Price info
          _buildPriceInfo(theme, currency),

          // Shipping info
          if (data.shippingAddress != null) ...[
            const SizedBox(height: 16),
            _buildShippingInfo(theme),
          ],

          // Tracking info
          if (data.trackingNumber != null) ...[
            const SizedBox(height: 16),
            _buildTrackingInfo(theme),
          ],

          // Actions
          if (data.actions != null && data.actions!.isNotEmpty)
            ActionButtons(
              actions: data.actions,
              onSendMessage: onSendMessage,
              onAction: onAction,
              onCopySuccess: onCopySuccess,
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, OrderItem item, TgoTheme theme, String currency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: theme.bgSecondary,
                  child: Icon(Icons.image_outlined, color: theme.textMuted, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.image_outlined, color: theme.textMuted, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.attributes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.attributes!.entries.map((e) => '${e.key}: ${e.value}').join(' | '),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                if (item.sku != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${item.quantity}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatPrice(item.totalPrice, currency),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo(TgoTheme theme, String currency) {
    return Column(
      children: [
        InfoRow(label: 'Subtotal', value: Text(formatPrice(data.subtotal, currency))),
        if (data.shippingFee != null && data.shippingFee! > 0)
          InfoRow(label: 'Shipping', value: Text(formatPrice(data.shippingFee, currency))),
        if (data.discount != null && data.discount! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: TextStyle(fontSize: 14, color: theme.errorColor)),
                Text('-${formatPrice(data.discount, currency)}',
                    style: TextStyle(fontSize: 14, color: theme.errorColor)),
              ],
            ),
          ),
        InfoRow(
          label: 'Total',
          value: Text(formatPrice(data.total, currency)),
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildShippingInfo(TgoTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: theme.textMuted, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.receiverName ?? ''} ${data.receiverPhone ?? ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.shippingAddress!,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfo(TgoTheme theme) {
    return Row(
      children: [
        Icon(Icons.local_shipping_outlined, color: theme.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          data.carrier ?? '',
          style: TextStyle(fontSize: 13, color: theme.textSecondary),
        ),
        const SizedBox(width: 8),
        Text(
          data.trackingNumber!,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  _StatusStyle _getStatusStyle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusStyle(
            bgColor: const Color(0xFFFEF9C3), textColor: const Color(0xFF854D0E), icon: Icons.access_time);
      case OrderStatus.paid:
        return _StatusStyle(
            bgColor: const Color(0xFFDBEAFE), textColor: const Color(0xFF1E40AF), icon: Icons.check_circle_outline);
      case OrderStatus.processing:
        return _StatusStyle(
            bgColor: const Color(0xFFE0E7FF), textColor: const Color(0xFF3730A3), icon: Icons.inventory_2);
      case OrderStatus.shipped:
        return _StatusStyle(
            bgColor: const Color(0xFFF3E8FF), textColor: const Color(0xFF6B21A8), icon: Icons.local_shipping);
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return _StatusStyle(
            bgColor: const Color(0xFFDCFCE7), textColor: const Color(0xFF166534), icon: Icons.check_circle);
      case OrderStatus.cancelled:
        return _StatusStyle(
            bgColor: const Color(0xFFF3F4F6), textColor: const Color(0xFF374151), icon: Icons.cancel_outlined);
      case OrderStatus.refunded:
        return _StatusStyle(
            bgColor: const Color(0xFFFEE2E2), textColor: const Color(0xFF991B1B), icon: Icons.error_outline);
    }
  }
}

class _StatusStyle {
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const _StatusStyle({required this.bgColor, required this.textColor, required this.icon});
}


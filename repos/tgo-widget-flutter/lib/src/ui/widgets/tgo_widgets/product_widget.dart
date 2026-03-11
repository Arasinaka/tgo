import 'package:flutter/material.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class ProductWidget extends StatelessWidget {
  final ProductWidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const ProductWidget({
    super.key,
    required this.data,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);
    final currency = data.currency ?? '¥';
    final hasDiscount = data.originalPrice != null && data.originalPrice! > data.price;

    return WidgetCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (data.imageUrl != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    data.imageUrl!,
                    width: double.infinity,
                    height: 192,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      height: 192,
                      color: theme.bgSecondary,
                      child: Icon(Icons.image_outlined, color: theme.textMuted, size: 48),
                    ),
                  ),
                ),
                if (data.discountLabel != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.errorColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data.discountLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                if (data.tags != null && data.tags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 4,
                      children: data.tags!.take(3).map((tag) => _buildTag(tag, theme)).toList(),
                    ),
                  ),

                // Name
                Text(
                  data.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Brand
                if (data.brand != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      data.brand!,
                      style: TextStyle(fontSize: 14, color: theme.textSecondary),
                    ),
                  ),

                // Description
                if (data.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.description!,
                      style: TextStyle(fontSize: 14, color: theme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Price
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatPrice(data.price, currency),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: theme.errorColor,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(data.originalPrice, currency),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Rating
                if (data.rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFACC15), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          data.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.textPrimary,
                          ),
                        ),
                        if (data.reviewCount != null)
                          Text(
                            ' (${data.reviewCount} reviews)',
                            style: TextStyle(fontSize: 14, color: theme.textMuted),
                          ),
                      ],
                    ),
                  ),

                // Stock status
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data.inStock ? (data.stockStatus ?? 'In Stock') : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: data.inStock ? theme.successColor : theme.errorColor,
                    ),
                  ),
                ),

                // Specs
                if (data.specs != null && data.specs!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: theme.borderPrimary)),
                    ),
                    child: Column(
                      children: data.specs!.take(4).map((spec) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                spec.key,
                                style: TextStyle(fontSize: 14, color: theme.textSecondary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                spec.value,
                                style: TextStyle(fontSize: 14, color: theme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag, TgoTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF7F1D1D).withOpacity(0.2) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: theme.isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}


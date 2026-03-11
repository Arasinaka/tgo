import 'package:flutter/material.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class ProductListWidget extends StatelessWidget {
  final ProductListWidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const ProductListWidget({
    super.key,
    required this.data,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return WidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (data.title != null || data.subtitle != null) ...[
            if (data.title != null)
              Row(
                children: [
                  Icon(Icons.grid_view_outlined, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.title!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            if (data.subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data.subtitle!,
                  style: TextStyle(fontSize: 14, color: theme.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Product Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: data.products.length,
            itemBuilder: (context, index) {
              return _buildProductItem(context, data.products[index], theme);
            },
          ),

          // Pagination Info
          if (data.totalCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'Total ${data.totalCount} items${data.hasMore ? ' · and more' : ''}',
                  style: TextStyle(fontSize: 14, color: theme.textSecondary),
                ),
              ),
            ),

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

  Widget _buildProductItem(BuildContext context, ProductListItem product, TgoTheme theme) {
    return InkWell(
      onTap: () {
        // Fallback action for tapping a product list item
        onAction?.call('view_product', {'product_id': product.productId});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.thumbnail != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    product.thumbnail!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: double.infinity,
                      color: theme.bgTertiary,
                      child: Icon(Icons.image_outlined, color: theme.textMuted, size: 24),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '¥${product.price}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.errorColor,
                  ),
                ),
                if (product.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFACC15), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        product.rating!.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: theme.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


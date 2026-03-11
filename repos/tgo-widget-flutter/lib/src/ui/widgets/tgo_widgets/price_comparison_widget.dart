import 'package:flutter/material.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class PriceComparisonWidget extends StatelessWidget {
  final PriceComparisonWidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const PriceComparisonWidget({
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
          // Title
          if (data.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                data.title!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ),

          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 0,
              headingRowColor: MaterialStateProperty.all(theme.bgTertiary),
              headingTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
              dataTextStyle: TextStyle(
                fontSize: 14,
                color: theme.textPrimary,
              ),
              border: TableBorder.all(color: theme.borderPrimary),
              columns: data.columns.map((col) => DataColumn(label: Text(col))).toList(),
              rows: List.generate(data.items.length, (index) {
                final item = data.items[index];
                final isRecommended = index == data.recommendedIndex;
                
                return DataRow(
                  color: isRecommended
                      ? MaterialStateProperty.all(theme.successColor.withOpacity(0.05))
                      : null,
                  cells: data.columns.map((col) {
                    final value = item[col] ?? '';
                    final isFirstCol = col == data.columns.first;

                    return DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: isRecommended ? theme.successColor : theme.textPrimary,
                            ),
                          ),
                          if (isRecommended && isFirstCol) ...[
                            const SizedBox(width: 8),
                            _buildRecommendedBadge(theme),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ),

          // Recommendation Reason
          if (data.recommendationReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.recommendationReason!,
                      style: TextStyle(fontSize: 14, color: theme.successColor),
                    ),
                  ),
                ],
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

  Widget _buildRecommendedBadge(TgoTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Recommended',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.isDark ? const Color(0xFFA7F3D0) : const Color(0xFF15803D),
        ),
      ),
    );
  }
}


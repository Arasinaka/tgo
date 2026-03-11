import 'package:flutter/material.dart';
import '../../../theme/tgo_theme.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final Widget value;
  final bool highlight;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return Padding(
      padding: EdgeInsets.only(top: highlight ? 8 : 4),
      child: Container(
        padding: EdgeInsets.only(top: highlight ? 8 : 0),
        decoration: BoxDecoration(
          border: highlight
              ? Border(top: BorderSide(color: theme.borderPrimary))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: highlight ? 15 : 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? theme.textPrimary : theme.textSecondary,
              ),
            ),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: highlight ? 16 : 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight ? theme.errorColor : theme.textPrimary,
              ),
              child: value,
            ),
          ],
        ),
      ),
    );
  }
}

class DividerRow extends StatelessWidget {
  const DividerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: theme.borderPrimary,
    );
  }
}


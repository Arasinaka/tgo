import 'package:flutter/material.dart';
import '../../../theme/tgo_theme.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Widget? icon;
  final Color? bgColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.icon,
    this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: theme.isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor ?? theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}


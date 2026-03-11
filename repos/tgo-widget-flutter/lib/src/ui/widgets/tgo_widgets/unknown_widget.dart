import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class UnknownWidget extends StatelessWidget {
  final WidgetData data;
  final ActionCallback? onAction;

  const UnknownWidget({
    super.key,
    required this.data,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF713F12).withOpacity(0.2) : const Color(0xFFFEFCE8),
        border: Border.all(
          color: theme.isDark ? const Color(0xFFA16207) : const Color(0xFFFEF08A),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: theme.isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unknown UI Component: ${data.type}',
                  style: TextStyle(
                    color: theme.isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'View raw data',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.isDark ? const Color(0xFFFACC15) : const Color(0xFFCA8A04),
                ),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? const Color(0xFF713F12).withOpacity(0.3)
                        : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(data.toJson()),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


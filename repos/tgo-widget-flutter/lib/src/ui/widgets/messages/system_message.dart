import 'package:flutter/material.dart';
import '../../../models/message.dart';
import '../../theme/tgo_theme.dart';

/// System message display
class SystemMessageWidget extends StatelessWidget {
  final SystemPayload payload;

  const SystemMessageWidget({
    super.key,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.bgTertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          payload.formattedContent,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


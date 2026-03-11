import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/tgo_theme.dart';

/// Header widget for the chat screen
class ChatHeader extends StatelessWidget {
  final String title;
  final String? logoUrl;
  final VoidCallback? onClose;
  final bool showClose;

  const ChatHeader({
    super.key,
    required this.title,
    this.logoUrl,
    this.onClose,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.bgPrimary,
        border: Border(
          bottom: BorderSide(color: theme.borderPrimary),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo
            if (logoUrl != null && logoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: logoUrl!.toLowerCase().endsWith('.svg')
                    ? SvgPicture.network(
                        logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => _defaultLogo(theme),
                      )
                    : Image.network(
                        logoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultLogo(theme),
                      ),
              )
            else
              _defaultLogo(theme),

            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ),

            // Close button
            if (showClose && onClose != null)
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close,
                  color: theme.textSecondary,
                ),
                tooltip: 'Close',
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultLogo(TgoTheme theme) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      package: 'tgo_widget',
      width: 40,
      height: 40,
      placeholderBuilder: (BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.support_agent,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}


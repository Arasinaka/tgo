import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/tgo_theme.dart';
import '../models/widget_types.dart';

typedef SendMessageCallback = void Function(String message);
typedef ActionCallback = void Function(String action, Map<String, dynamic>? payload);

class ActionButtons extends StatelessWidget {
  final List<WidgetAction>? actions;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const ActionButtons({
    super.key,
    this.actions,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    if (actions == null || actions!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions!.map((action) => _ActionButton(
          action: action,
          onSendMessage: onSendMessage,
          onAction: onAction,
          onCopySuccess: onCopySuccess,
        )).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final WidgetAction action;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const _ActionButton({
    required this.action,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  Future<void> _handleTap(BuildContext context) async {
    final uri = action.action;
    
    // Parse Action URI
    if (uri.startsWith('url://')) {
      final url = uri.substring(6);
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } else if (uri.startsWith('msg://')) {
      String msg = uri.substring(6);
      try {
        msg = Uri.decodeComponent(msg);
      } catch (e) {
        // If decoding fails (e.g. already plain text or malformed percent encoding), use as is
        debugPrint('Error decoding msg URI: $e');
      }
      onSendMessage?.call(msg);
      _showToast(context, 'Message sent');
    } else if (uri.startsWith('copy://')) {
      String text = uri.substring(7);
      try {
        text = Uri.decodeComponent(text);
      } catch (e) {
        debugPrint('Error decoding copy URI: $e');
      }
      await Clipboard.setData(ClipboardData(text: text));
      onCopySuccess?.call(text);
      _showToast(context, 'Copied to clipboard');
    } else if (action.url != null && action.url!.isNotEmpty) {
      if (await canLaunchUrl(Uri.parse(action.url!))) {
        await launchUrl(Uri.parse(action.url!));
      }
    } else {
      onAction?.call(action.action, action.payload);
    }
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);
    
    Color bgColor;
    Color textColor;
    BorderSide? border;

    switch (action.style) {
      case 'primary':
        bgColor = theme.primaryColor;
        textColor = Colors.white;
        border = null;
        break;
      case 'danger':
        bgColor = theme.errorColor;
        textColor = Colors.white;
        border = null;
        break;
      case 'link':
        bgColor = Colors.transparent;
        textColor = theme.primaryColor;
        border = null;
        break;
      default:
        bgColor = Colors.transparent;
        textColor = theme.textPrimary;
        border = BorderSide(color: theme.borderPrimary);
    }

    final isLink = action.style == 'link';

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLink ? 0 : 16,
          vertical: isLink ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border != null ? Border.fromBorderSide(border) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                decoration: isLink ? TextDecoration.underline : null,
              ),
            ),
            const SizedBox(width: 4),
            _buildIcon(textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    final uri = action.action;
    IconData? iconData;

    if (uri.startsWith('url://') || (action.url != null && action.url!.isNotEmpty)) {
      iconData = Icons.open_in_new;
    } else if (uri.startsWith('msg://')) {
      iconData = Icons.chat_bubble_outline;
    } else if (uri.startsWith('copy://')) {
      iconData = Icons.copy;
    }

    if (iconData == null) return const SizedBox.shrink();

    return Icon(iconData, size: 14, color: color);
  }
}

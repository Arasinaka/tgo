import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/tgo_config.dart';
import '../tgo_widget_impl.dart';
import 'theme/tgo_theme.dart';

/// Floating launcher button for the chat widget
///
/// Add this to your widget tree (usually in a Stack) to show a floating
/// button that opens the chat when tapped.
///
/// ```dart
/// Stack(
///   children: [
///     YourAppContent(),
///     TgoWidgetLauncher(),
///   ],
/// )
/// ```
class TgoWidgetLauncher extends StatefulWidget {
  /// Override the position (defaults to config.position)
  final WidgetPosition? position;

  /// Override the theme color (defaults to config.themeColor)
  final Color? themeColor;

  /// Custom logo widget
  final Widget? logo;

  /// Whether to show the unread badge
  final bool showBadge;

  /// Custom size for the launcher button
  final double size;

  const TgoWidgetLauncher({
    super.key,
    this.position,
    this.themeColor,
    this.logo,
    this.showBadge = true,
    this.size = 56,
  });

  @override
  State<TgoWidgetLauncher> createState() => _TgoWidgetLauncherState();
}

class _TgoWidgetLauncherState extends State<TgoWidgetLauncher>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _isPressed = false;
  bool _isHovered = false;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSubscription;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to unread count
    _unreadSubscription = TgoWidget.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });

    // Get initial unread count
    _unreadCount = TgoWidget.unreadCount;
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() async {
    if (!TgoWidget.isInitialized) return;

    setState(() => _isOpen = !_isOpen);

    if (_isOpen) {
      await TgoWidget.show(context);
      if (mounted) {
        setState(() => _isOpen = false);
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final config = TgoWidget.config;
    final position = widget.position ?? config.position;
    final themeColor = widget.themeColor ?? config.themeColor;

    final isDark = config.darkMode ??
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final theme = TgoTheme(primaryColor: themeColor, isDark: isDark);

    return Positioned(
      left: _getLeft(position),
      right: _getRight(position),
      top: _getTop(position),
      bottom: _getBottom(position),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final hoverScale = _isHovered && !_isPressed ? 1.06 : 1.0;
              return Transform.scale(
                scale: _scaleAnimation.value * hoverScale,
                child: child,
              );
            },
            child: _buildButton(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(TgoTheme theme) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _isOpen ? theme.primaryColor : (theme.isDark ? const Color(0xFF2D2D2D) : Colors.white),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.isDark ? 0.4 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Button content
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isOpen
                  ? Icon(
                      Icons.close,
                      key: const ValueKey('close'),
                      color: Colors.white,
                      size: 24,
                    )
                  : widget.logo ??
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        package: 'tgo_widget',
                        width: 24,
                        height: 24,
                        placeholderBuilder: (context) => Icon(
                          Icons.chat_bubble_outline,
                          key: const ValueKey('chat'),
                          color:
                              theme.isDark ? Colors.white : theme.primaryColor,
                          size: 24,
                        ),
                      ),
            ),
          ),

          // Unread badge
          if (widget.showBadge && _unreadCount > 0 && !_isOpen)
            Positioned(
              top: -4,
              right: -4,
              child: _UnreadBadge(count: _unreadCount),
            ),
        ],
      ),
    );
  }

  double? _getLeft(WidgetPosition position) {
    switch (position) {
      case WidgetPosition.bottomLeft:
      case WidgetPosition.topLeft:
        return 16;
      default:
        return null;
    }
  }

  double? _getRight(WidgetPosition position) {
    switch (position) {
      case WidgetPosition.bottomRight:
      case WidgetPosition.topRight:
        return 16;
      default:
        return null;
    }
  }

  double? _getTop(WidgetPosition position) {
    switch (position) {
      case WidgetPosition.topLeft:
      case WidgetPosition.topRight:
        return 16;
      default:
        return null;
    }
  }

  double? _getBottom(WidgetPosition position) {
    switch (position) {
      case WidgetPosition.bottomLeft:
      case WidgetPosition.bottomRight:
        return 16;
      default:
        return null;
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}


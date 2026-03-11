import 'package:flutter/material.dart';

/// Theme data for TGO Widget
class TgoTheme {
  final Color primaryColor;
  final bool isDark;

  const TgoTheme({
    this.primaryColor = const Color(0xFF2F80ED),
    this.isDark = false,
  });

  /// Background colors
  Color get bgPrimary => isDark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get bgSecondary =>
      isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB);
  Color get bgTertiary =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);
  Color get bgInput =>
      isDark ? const Color(0xFF2D2D2D) : Colors.white;

  /// Text colors
  Color get textPrimary =>
      isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
  Color get textSecondary =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  /// Border colors
  Color get borderPrimary =>
      isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E7EB);

  /// Message bubble colors
  Color get userBubbleBg => primaryColor;
  Color get userBubbleText => Colors.white;
  Color get agentBubbleBg => bgTertiary;
  Color get agentBubbleText => textPrimary;

  /// Error color
  Color get errorColor => const Color(0xFFEF4444);

  /// Success color
  Color get successColor => const Color(0xFF10B981);

  /// Shadow
  BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
        blurRadius: 30,
        offset: const Offset(0, 8),
      );

  /// Create Flutter ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: bgPrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  /// Copy with new values
  TgoTheme copyWith({
    Color? primaryColor,
    bool? isDark,
  }) {
    return TgoTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      isDark: isDark ?? this.isDark,
    );
  }
}

/// Inherited widget for theme
class TgoThemeProvider extends InheritedWidget {
  final TgoTheme theme;

  const TgoThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static TgoTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<TgoThemeProvider>();
    return provider?.theme ?? const TgoTheme();
  }

  @override
  bool updateShouldNotify(TgoThemeProvider oldWidget) {
    return theme.primaryColor != oldWidget.theme.primaryColor ||
        theme.isDark != oldWidget.theme.isDark;
  }
}


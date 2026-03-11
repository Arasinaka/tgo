import 'package:flutter/material.dart';

/// Position for the widget launcher button
enum WidgetPosition {
  bottomRight,
  bottomLeft,
  topRight,
  topLeft,
}

/// Configuration for TGO Widget
class TgoWidgetConfig {
  /// Widget title displayed in the header
  final String title;

  /// Primary theme color
  final Color themeColor;

  /// Position of the launcher button
  final WidgetPosition position;

  /// Welcome message shown to visitors
  final String? welcomeMessage;

  /// Custom logo URL
  final String? logoUrl;

  /// Enable dark mode
  final bool? darkMode;

  /// Locale for internationalization (e.g., 'en', 'zh')
  final String? locale;

  const TgoWidgetConfig({
    this.title = 'Customer Service',
    this.themeColor = const Color(0xFF2F80ED),
    this.position = WidgetPosition.bottomRight,
    this.welcomeMessage,
    this.logoUrl,
    this.darkMode,
    this.locale,
  });

  TgoWidgetConfig copyWith({
    String? title,
    Color? themeColor,
    WidgetPosition? position,
    String? welcomeMessage,
    String? logoUrl,
    bool? darkMode,
    String? locale,
  }) {
    return TgoWidgetConfig(
      title: title ?? this.title,
      themeColor: themeColor ?? this.themeColor,
      position: position ?? this.position,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      logoUrl: logoUrl ?? this.logoUrl,
      darkMode: darkMode ?? this.darkMode,
      locale: locale ?? this.locale,
    );
  }
}


/// TGO Widget - A Flutter package for customer service chat
///
/// This package provides an easy-to-integrate chat widget for customer service.
///
/// ## Quick Start
///
/// ```dart
/// // Initialize in main.dart
/// await TgoWidget.init(
///   apiKey: 'your-platform-api-key',
///   apiBase: 'https://api.example.com',
/// );
///
/// // Add launcher to your app
/// Stack(
///   children: [
///     YourAppContent(),
///     TgoWidgetLauncher(),
///   ],
/// )
/// ```
library tgo_widget;

// Configuration
export 'src/config/tgo_config.dart';
export 'src/config/visitor_info.dart';

// Models
export 'src/models/message.dart';
export 'src/models/visitor.dart';
export 'src/models/api_types.dart';

// Main widget and launcher
export 'src/tgo_widget_impl.dart';
export 'src/ui/launcher.dart';
export 'src/ui/chat_screen.dart';

// Theme
export 'src/ui/theme/tgo_theme.dart';

// State (for advanced usage)
export 'src/state/chat_provider.dart';
export 'src/state/chat_state.dart';

// Localization
export 'src/i18n/tgo_localizations.dart';


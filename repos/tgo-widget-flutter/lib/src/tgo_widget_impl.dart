import 'dart:async';
import 'package:flutter/material.dart';
import 'config/tgo_config.dart';
import 'config/visitor_info.dart';
import 'services/visitor_service.dart';
import 'services/im_service.dart';
import 'state/chat_provider.dart';
import 'ui/chat_screen.dart';

/// Connection status for the IM service
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// TgoWidget - Main entry point for the TGO customer service widget
///
/// This singleton class manages the widget lifecycle, configuration,
/// and provides a simple API for integration.
///
/// ## Usage
///
/// ```dart
/// // Initialize once at app startup
/// await TgoWidget.init(
///   apiKey: 'your-api-key',
///   apiBase: 'https://api.example.com',
/// );
///
/// // Show the chat screen
/// TgoWidget.show(context);
///
/// // Listen to unread count
/// TgoWidget.unreadCountStream.listen((count) {
///   print('Unread messages: $count');
/// });
/// ```
class TgoWidget {
  TgoWidget._();

  static TgoWidget? _instance;

  /// Get the singleton instance
  static TgoWidget get instance {
    _instance ??= TgoWidget._();
    return _instance!;
  }

  // Configuration
  String? _apiKey;
  String? _apiBase;
  TgoWidgetConfig _config = const TgoWidgetConfig();
  VisitorInfo? _visitor;

  // Services
  VisitorService? _visitorService;
  IMService? _imService;

  // State
  ChatProvider? _chatProvider;
  bool _initialized = false;

  // Subscriptions
  StreamSubscription<int>? _unreadSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  // Stream controllers
  final _unreadCountController = StreamController<int>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  /// Stream of unread message count
  static Stream<int> get unreadCountStream =>
      instance._unreadCountController.stream;

  /// Stream of connection status
  static Stream<ConnectionStatus> get connectionStatusStream =>
      instance._connectionStatusController.stream;

  /// Current unread count
  static int get unreadCount => instance._chatProvider?.unreadCount ?? 0;

  /// Current connection status
  static ConnectionStatus get connectionStatus =>
      instance._chatProvider?.connectionStatus ?? ConnectionStatus.disconnected;

  /// Whether the widget is initialized
  static bool get isInitialized => instance._initialized;

  /// Current configuration
  static TgoWidgetConfig get config => instance._config;

  /// API base URL
  static String? get apiBase => instance._apiBase;

  /// Platform API key
  static String? get apiKey => instance._apiKey;

  /// Initialize the TGO Widget
  ///
  /// Must be called before using any other methods.
  ///
  /// [apiKey] - Your platform API key
  /// [apiBase] - API base URL (optional, defaults to production)
  /// [config] - Widget configuration (optional)
  /// [visitor] - Visitor information (optional)
  static Future<void> init({
    required String apiKey,
    String? apiBase,
    TgoWidgetConfig config = const TgoWidgetConfig(),
    VisitorInfo? visitor,
  }) async {
    final widget = instance;

    if (widget._initialized) {
      // Check if we can reuse or need to re-init
      if (widget._apiKey == apiKey && 
          (apiBase == null || widget._apiBase == apiBase)) {
        // Just update config and visitor
        updateConfig(config);
        if (visitor != null) setVisitor(visitor);
        return;
      }
      await dispose();
    }
    
    widget._apiKey = apiKey;
    widget._apiBase = apiBase ?? 'https://api.tgo.ai';
    widget._config = config;
    widget._visitor = visitor;

    // Initialize services
    widget._visitorService = VisitorService(
      apiBase: widget._apiBase!,
      apiKey: apiKey,
    );
    widget._visitorService!.updateVisitorInfo(visitor);

    widget._imService = IMService(
      apiBase: widget._apiBase!,
    );

    // Initialize chat provider
    widget._chatProvider = ChatProvider(
      visitorService: widget._visitorService!,
      imService: widget._imService!,
      config: config,
      visitor: visitor,
    );

    // Forward streams
    widget._unreadSubscription?.cancel();
    widget._unreadSubscription =
        widget._chatProvider!.unreadCountStream.listen((count) {
      if (!widget._unreadCountController.isClosed) {
        widget._unreadCountController.add(count);
      }
    });

    widget._statusSubscription?.cancel();
    widget._statusSubscription =
        widget._chatProvider!.connectionStatusStream.listen((status) {
      if (!widget._connectionStatusController.isClosed) {
        widget._connectionStatusController.add(status);
      }
    });

    // Connect to IM service
    await widget._chatProvider!.initialize();

    widget._initialized = true;
  }

  /// Update visitor information
  ///
  /// If platformOpenId changes, it will clear cache and re-register.
  static Future<void> setVisitor(VisitorInfo visitor) async {
    final widget = instance;
    if (!widget._initialized) return;

    final oldOpenId = widget._visitor?.platformOpenId;
    widget._visitor = visitor;
    
    if (oldOpenId != visitor.platformOpenId) {
      // Identity changed, need to re-initialize everything
      await widget._imService?.disconnect();
      widget._chatProvider?.updateVisitor(visitor);
      await widget._chatProvider?.initialize();
    } else {
      // Just metadata changed, send an update register call
      widget._chatProvider?.updateVisitor(visitor);
      await widget._chatProvider?.initialize(); // This will call register again
    }
  }

  /// Clear visitor information (e.g. on logout)
  ///
  /// This will disconnect IM and return to anonymous state.
  static Future<void> clearVisitor() async {
    final widget = instance;
    if (!widget._initialized) return;

    widget._visitor = null;
    await widget._imService?.disconnect();
    widget._chatProvider?.updateVisitor(null);
    await widget._chatProvider?.initialize();
  }

  /// Update widget configuration
  static void updateConfig(TgoWidgetConfig config) {
    instance._config = config;
    instance._chatProvider?.updateConfig(config);
  }

  /// Show the chat screen as a modal bottom sheet
  static Future<void> show(BuildContext context) async {
    if (!instance._initialized) {
      throw StateError(
          'TgoWidget not initialized. Call TgoWidget.init() first.');
    }

    // Clear unread count when opening
    instance._chatProvider?.clearUnreadCount();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatScreen(
        provider: instance._chatProvider!,
        config: instance._config,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Show the chat screen as a full-screen page
  static Future<void> showFullScreen(BuildContext context) async {
    if (!instance._initialized) {
      throw StateError(
          'TgoWidget not initialized. Call TgoWidget.init() first.');
    }

    // Clear unread count when opening
    instance._chatProvider?.clearUnreadCount();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          provider: instance._chatProvider!,
          config: instance._config,
          fullScreen: true,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Hide the chat screen (if shown as overlay)
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Send a text message programmatically
  static Future<void> sendMessage(String text) async {
    if (!instance._initialized) {
      throw StateError(
          'TgoWidget not initialized. Call TgoWidget.init() first.');
    }
    await instance._chatProvider?.sendMessage(text);
  }

  /// Clear all unread count
  static void clearUnreadCount() {
    instance._chatProvider?.clearUnreadCount();
  }

  /// Disconnect and cleanup resources
  static Future<void> dispose() async {
    instance._unreadSubscription?.cancel();
    instance._statusSubscription?.cancel();
    await instance._imService?.disconnect();
    instance._chatProvider?.dispose();
    await instance._unreadCountController.close();
    await instance._connectionStatusController.close();
    instance._initialized = false;
    _instance = null;
  }

  /// Get the chat provider for advanced usage
  static ChatProvider? get chatProvider => instance._chatProvider;
}


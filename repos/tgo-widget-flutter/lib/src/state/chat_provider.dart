import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wukong_easy_sdk/wukong_easy_sdk.dart' as wk;
import '../config/tgo_config.dart';
import '../models/message.dart';
import '../models/api_types.dart';
import '../config/visitor_info.dart';
import '../services/visitor_service.dart';
import '../services/im_service.dart';
import '../services/history_service.dart';
import '../services/chat_service.dart';
import '../services/platform_service.dart';
import '../services/upload_service.dart';
import 'upload_controller.dart';
import '../tgo_widget_impl.dart';
import 'chat_state.dart';

/// Provider for chat state management
class ChatProvider extends ChangeNotifier {
  final VisitorService _visitorService;
  final IMService _imService;
  late final HistoryService _historyService;
  late final ChatService _chatService;
  late final PlatformService _platformService;
  late final UploadService _uploadService;
  late final UploadController _uploadController;

  TgoWidgetConfig _config;
  VisitorInfo? _visitor;
  ChatState _state = const ChatState();

  // Stream controllers
  final _unreadCountController = StreamController<int>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  // Streaming timeout timer
  Timer? _streamTimer;
  static const _streamTimeoutMs = 60000;

  ChatProvider({
    required VisitorService visitorService,
    required IMService imService,
    required TgoWidgetConfig config,
    VisitorInfo? visitor,
  })  : _visitorService = visitorService,
        _imService = imService,
        _config = config,
        _visitor = visitor {
    _visitorService.updateVisitorInfo(visitor);
    _historyService = HistoryService(apiBase: _visitorService.apiBase);
    _chatService = ChatService(apiBase: _visitorService.apiBase);
    _platformService = PlatformService(
      apiBase: _visitorService.apiBase,
      apiKey: _visitorService.apiKey,
    );
    _uploadService = UploadService(
      apiBase: _visitorService.apiBase,
      apiKey: _visitorService.apiKey,
    );
    _uploadController = UploadController(
      uploadService: _uploadService,
      imService: _imService,
      provider: this,
    );
  }

  /// Update visitor info
  void updateVisitor(VisitorInfo? visitor) {
    if (_visitor?.platformOpenId != visitor?.platformOpenId) {
      // PlatformOpenId changed, need to clear cache and reconnect later
      _visitorService.clearCache();
      // Clear messages and unread count for the new user
      _updateState(_state.copyWith(
        messages: [],
        unreadCount: 0,
      ));
      _unreadCountController.add(0);
    }
    _visitor = visitor;
    _visitorService.updateVisitorInfo(visitor);
  }

  /// Current config
  TgoWidgetConfig get config => _config;

  /// Current state
  ChatState get state => _state;

  /// Stream of unread count changes
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  /// Current unread count
  int get unreadCount => _state.unreadCount;

  /// Current connection status
  ConnectionStatus get connectionStatus => _state.connectionStatus;

  /// List of messages
  List<ChatMessage> get messages => _state.messages;

  /// Whether initialized
  bool get isInitialized => _imService.isInitialized;

  /// Update state and notify listeners
  void _updateState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Update configuration
  void updateConfig(TgoWidgetConfig config) {
    _config = config;
    // Inject welcome message if needed
    if (config.welcomeMessage != null &&
        config.welcomeMessage!.isNotEmpty &&
        !_state.messages.any((m) => m.id == 'welcome')) {
      _ensureWelcomeMessage(config.welcomeMessage!);
    }
  }

  /// Initialize the chat (register visitor, connect IM)
  Future<void> initialize() async {
    if (_state.isInitializing) return;

    _updateState(_state.copyWith(isInitializing: true, error: null));

    try {
      // Fetch platform info first (with retry)
      try {
        final platformInfo = await _retryOperation(
          () => _platformService.fetchPlatformInfo(),
          maxRetries: 2,
          operationName: 'Platform info fetch',
        );

        // Update title if displayName exists, regardless of config
        if (platformInfo.displayName != null && platformInfo.displayName!.isNotEmpty) {
          _config = _config.copyWith(title: platformInfo.displayName);
        }

        if (platformInfo.config != null) {
          final cfg = platformInfo.config!;
          // Update local config with platform info
          _config = _config.copyWith(
            title: (platformInfo.displayName != null && platformInfo.displayName!.isNotEmpty)
                ? platformInfo.displayName
                : cfg.widgetTitle,
            themeColor: cfg.themeColor != null
                ? Color(int.parse(cfg.themeColor!.replaceFirst('#', '0xFF')))
                : null,
            logoUrl: cfg.logoUrl,
            welcomeMessage: cfg.welcomeMessage,
          );
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[ChatProvider] Platform info fetch error (non-fatal): $e');
      }

      // Register visitor (with retry)
      final visitor = await _retryOperation(
        () => _visitorService.ensureRegistered(),
        maxRetries: 3,
        operationName: 'Visitor registration',
      );

      debugPrint('[ChatProvider] Visitor registered: ${visitor.visitorId}');

      if (visitor.imToken == null) {
        throw Exception('Missing IM token from visitor registration');
      }

      // Update state with visitor info
      _updateState(_state.copyWith(
        myUid: visitor.imUid,
        platformOpenId: visitor.platformOpenId,
        channelId: visitor.channelId,
        channelType: visitor.channelType ?? 251,
      ));

      // Initialize IM service
      await _imService.init(
        uid: visitor.imUid,
        token: visitor.imToken!,
        target: visitor.channelId,
        channelType: visitor.channelType ?? 251,
      );

      // Setup message listener
      _imService.addMessageListener(_onMessageReceived);
      _imService.addStatusListener(_onStatusChanged);
      _imService.addCustomEventListener(_onCustomEvent);

      // Connect to IM
      await _imService.connect();

      // Load initial history
      await loadInitialHistory();

      // Add welcome message if configured
      if (_config.welcomeMessage != null &&
          _config.welcomeMessage!.isNotEmpty) {
        _ensureWelcomeMessage(_config.welcomeMessage!);
      }

      _updateState(_state.copyWith(isInitializing: false));
    } catch (e) {
      debugPrint('[ChatProvider] Initialization error: $e');
      _updateState(_state.copyWith(
        isInitializing: false,
        error: e.toString(),
      ));
    }
  }

  /// Handle incoming message
  void _onMessageReceived(wk.Message message) {
    // Skip self echoes
    if (message.fromUid == _state.myUid) return;

    debugPrint('[ChatProvider] Message received: ${message.messageId}');

    final payload = _toPayloadFromAny(message.payload);

    final chatMessage = ChatMessage(
      id: message.messageId,
      role: 'agent',
      payload: payload,
      time: DateTime.fromMillisecondsSinceEpoch(message.timestamp * 1000),
      messageSeq: message.messageSeq,
      clientMsgNo: message.clientMsgNo,
      fromUid: message.fromUid,
      channelId: message.channelId,
      channelType: message.channelType.value,
    );

    // Check for duplicates
    if (_state.messages.any((m) => m.id == chatMessage.id)) return;

    // Increment unread count
    _incrementUnreadCount();

    // Add message to list
    final messages = [..._state.messages, chatMessage];
    _updateState(_state.copyWith(messages: messages));
  }

  /// Handle status change
  void _onStatusChanged(ConnectionStatus status) {
    _updateState(_state.copyWith(connectionStatus: status));
    _connectionStatusController.add(status);
  }

  /// Handle custom events (streaming)
  void _onCustomEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final id = event['id'] as String? ?? '';

    if (type == '___TextMessageStart') {
      debugPrint('[ChatProvider] Stream started: $id');
      _markStreamingStart(id);
      _incrementUnreadCount();
    } else if (type == '___TextMessageContent') {
      final chunk = event['data'] as String? ?? '';
      if (chunk.isNotEmpty) {
        _appendStreamData(id, chunk);
      }
    } else if (type == '___TextMessageEnd') {
      final data = event['data'];
      final errorMessage =
          (data != null && data.toString().isNotEmpty) ? data.toString() : null;
      debugPrint('[ChatProvider] Stream ended: $id, error: $errorMessage');
      _finalizeStreamMessage(id, errorMessage: errorMessage);
      _markStreamingEnd();
    }
  }

  /// Convert raw payload to MessagePayload
  MessagePayload _toPayloadFromAny(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return MessagePayload.fromJson(raw);
    }
    if (raw is String) {
      return TextPayload(content: raw);
    }
    return TextPayload(content: raw?.toString() ?? '');
  }

  /// Send a text message
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final clientMsgNo = _generateClientMsgNo();
    final id = 'u-${DateTime.now().millisecondsSinceEpoch}';

    // Create user message
    final userMessage = ChatMessage(
      id: id,
      role: 'user',
      payload: TextPayload(content: trimmed),
      time: DateTime.now(),
      status: MessageStatus.sending,
      clientMsgNo: clientMsgNo,
    );

    // 1. 先将消息渲染到UI上
    addMessage(userMessage);

    try {
      // Cancel ongoing stream if any
      if (_state.isStreaming) {
        await cancelStreaming(reason: 'auto_cancel_on_new_send');
      }

      // 2. 通过websocket发送消息
      await _imService.sendText(trimmed, clientMsgNo: clientMsgNo);

      debugPrint('[ChatProvider] Message sent via IM, clientMsgNo: $clientMsgNo');

      // 发送成功后，更新状态为 sent
      updateMessageStatus(id, MessageStatus.sent);

      // 3. 再调用 /v1/chat/completion 接口
      try {
        await _chatService.sendCompletion(
          apiKey: _visitorService.apiKey,
          message: trimmed,
          fromUid: _state.platformOpenId ?? _state.myUid!,
          channelId: _state.channelId,
          channelType: _state.channelType,
        );
      } catch (e) {
        debugPrint('[ChatProvider] Completion error (non-fatal): $e');
        // 虽然 completion 失败了，但消息已经通过 IM 发送成功，不重置状态
      }
    } catch (e) {
      debugPrint('[ChatProvider] Send error: $e');
      updateMessageStatus(id, MessageStatus.failed);
      _updateState(_state.copyWith(error: e.toString()));
    }
  }

  /// Upload and send files
  Future<void> uploadFiles(List<File> files) async {
    for (final file in files) {
      // ignore: unawaited_futures
      _uploadController.uploadFile(file);
    }
  }

  /// Cancel an ongoing upload
  void cancelUpload(String messageId) {
    _uploadController.cancelUpload(messageId);
  }

  /// Retry a failed upload
  Future<void> retryUpload(String messageId) async {
    await _uploadController.retryUpload(messageId);
  }

  /// Call completion API for a message
  Future<void> sendCompletion(String message) async {
    if (_state.myUid == null) return;

    await _chatService.sendCompletion(
      apiKey: _visitorService.apiKey,
      message: message,
      fromUid: _state.platformOpenId ?? _state.myUid!,
      channelId: _state.channelId,
      channelType: _state.channelType,
    );
  }

  /// Update message status
  void updateMessageStatus(String messageId, MessageStatus status) {
    final messages = _state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(status: status);
      }
      return m;
    }).toList();
    _updateState(_state.copyWith(messages: messages));
  }

  /// Load initial history
  Future<void> loadInitialHistory({int limit = 20}) async {
    if (_state.channelId == null || _state.channelType == null) return;
    if (_state.historyLoading) return;

    _updateState(_state.copyWith(historyLoading: true, historyError: null));

    try {
      final response = await _historyService.syncMessages(
        platformApiKey: _visitorService.apiKey,
        channelId: _state.channelId!,
        channelType: _state.channelType!,
        limit: limit,
        pullMode: 1, // Pull up (newest)
      );

      final historyMessages = response.messages
          .map((m) => _mapHistoryToMessage(m))
          .toList()
        ..sort((a, b) => (a.messageSeq ?? 0).compareTo(b.messageSeq ?? 0));

      // Merge with existing messages (deduplicate)
      final existingIds = _state.messages.map((m) => m.id).toSet();
      final newMessages =
          historyMessages.where((m) => !existingIds.contains(m.id)).toList();

      final allMessages = [...newMessages, ..._state.messages];

      // Find earliest seq
      int? earliestSeq;
      for (final m in allMessages) {
        if (m.messageSeq != null) {
          if (earliestSeq == null || m.messageSeq! < earliestSeq) {
            earliestSeq = m.messageSeq;
          }
        }
      }

      _updateState(_state.copyWith(
        messages: allMessages,
        historyLoading: false,
        historyHasMore: response.more == 1,
        earliestSeq: earliestSeq,
      ));
    } catch (e) {
      debugPrint('[ChatProvider] Load history error: $e');
      _updateState(_state.copyWith(
        historyLoading: false,
        historyError: e.toString(),
      ));
    }
  }

  /// Load more history (older messages)
  Future<void> loadMoreHistory({int limit = 20}) async {
    if (_state.channelId == null || _state.channelType == null) return;
    if (_state.historyLoading) return;
    if (!_state.historyHasMore) return;

    final startSeq = _state.earliestSeq ?? 0;

    _updateState(_state.copyWith(historyLoading: true, historyError: null));

    try {
      final response = await _historyService.syncMessages(
        platformApiKey: _visitorService.apiKey,
        channelId: _state.channelId!,
        channelType: _state.channelType!,
        startSeq: startSeq,
        limit: limit,
        pullMode: 0, // Pull down (older)
      );

      final historyMessages = response.messages
          .map((m) => _mapHistoryToMessage(m))
          .toList()
        ..sort((a, b) => (a.messageSeq ?? 0).compareTo(b.messageSeq ?? 0));

      // Merge with existing messages (deduplicate)
      final existingIds = _state.messages.map((m) => m.id).toSet();
      final newMessages =
          historyMessages.where((m) => !existingIds.contains(m.id)).toList();

      final allMessages = [...newMessages, ..._state.messages];

      // Find earliest seq
      int? earliestSeq = _state.earliestSeq;
      for (final m in newMessages) {
        if (m.messageSeq != null) {
          if (earliestSeq == null || m.messageSeq! < earliestSeq) {
            earliestSeq = m.messageSeq;
          }
        }
      }

      _updateState(_state.copyWith(
        messages: allMessages,
        historyLoading: false,
        historyHasMore: response.more == 1,
        earliestSeq: earliestSeq,
      ));
    } catch (e) {
      debugPrint('[ChatProvider] Load more history error: $e');
      _updateState(_state.copyWith(
        historyLoading: false,
        historyError: e.toString(),
      ));
    }
  }

  /// Map history message to ChatMessage
  ChatMessage _mapHistoryToMessage(WuKongIMMessage m) {
    final isStreamEnded = m.settingFlags?.stream == true &&
        m.end == 1 &&
        m.streamData != null &&
        m.streamData!.isNotEmpty;

    final payload = isStreamEnded
        ? TextPayload(content: m.streamData!)
        : _toPayloadFromAny(m.payload);

    return ChatMessage(
      id: m.messageIdStr ?? m.clientMsgNo ?? 'h-${m.messageSeq}',
      role: m.fromUid == _state.myUid ? 'user' : 'agent',
      payload: payload,
      time: DateTime.fromMillisecondsSinceEpoch((m.timestamp ?? 0) * 1000),
      messageSeq: m.messageSeq,
      clientMsgNo: m.clientMsgNo,
      fromUid: m.fromUid,
      channelId: m.channelId,
      channelType: m.channelType,
      errorMessage: m.error,
    );
  }

  /// Mark streaming start
  void _markStreamingStart(String clientMsgNo) {
    _streamTimer?.cancel();

    final messages = _state.messages.toList();
    final index = messages.indexWhere((m) => m.clientMsgNo == clientMsgNo);

    if (index < 0) {
      // Add a loading message if not exists
      messages.add(ChatMessage(
        id: 'loading-$clientMsgNo',
        role: 'agent',
        payload: const AiLoadingPayload(),
        time: DateTime.now(),
        clientMsgNo: clientMsgNo,
      ));
    }

    _updateState(_state.copyWith(
      messages: messages,
      isStreaming: true,
      streamCanceling: false,
      streamingClientMsgNo: clientMsgNo,
    ));

    // Auto timeout
    _streamTimer = Timer(Duration(milliseconds: _streamTimeoutMs), () {
      if (_state.isStreaming && _state.streamingClientMsgNo == clientMsgNo) {
        _markStreamingEnd();
      }
    });
  }

  /// Mark streaming end
  void _markStreamingEnd() {
    _streamTimer?.cancel();
    _updateState(_state.copyWith(
      isStreaming: false,
      streamCanceling: false,
      streamingClientMsgNo: null,
    ));
  }

  /// Append stream data to message
  void _appendStreamData(String clientMsgNo, String data) {
    if (clientMsgNo.isEmpty || data.isEmpty) return;

    final messages = _state.messages.toList();
    final index = messages.indexWhere((m) => m.clientMsgNo == clientMsgNo);

    if (index >= 0) {
      // Update existing message
      final existing = messages[index];
      messages[index] = existing.copyWith(
        streamData: (existing.streamData ?? '') + data,
      );
    } else {
      // Create new streaming message
      messages.add(ChatMessage(
        id: 'stream-$clientMsgNo',
        role: 'agent',
        payload: const TextPayload(content: ''),
        time: DateTime.now(),
        clientMsgNo: clientMsgNo,
        streamData: data,
      ));
    }

    _updateState(_state.copyWith(messages: messages));

    // Ensure streaming state is set
    if (!_state.isStreaming) {
      _markStreamingStart(clientMsgNo);
    }
  }

  /// Finalize stream message
  void _finalizeStreamMessage(String clientMsgNo, {String? errorMessage}) {
    if (clientMsgNo.isEmpty) return;

    final messages = _state.messages.map((m) {
      if (m.clientMsgNo == clientMsgNo) {
        return m.clearStreamData().copyWith(errorMessage: errorMessage);
      }
      return m;
    }).toList();

    _updateState(_state.copyWith(messages: messages));

    if (_state.streamingClientMsgNo == clientMsgNo) {
      _markStreamingEnd();
    }
  }

  /// Cancel ongoing streaming
  Future<void> cancelStreaming({String reason = 'user_cancel'}) async {
    if (_state.streamCanceling) return;

    _updateState(_state.copyWith(streamCanceling: true));

    try {
      if (_state.streamingClientMsgNo != null) {
        await _chatService.cancelStream(
          platformApiKey: _visitorService.apiKey,
          clientMsgNo: _state.streamingClientMsgNo!,
          reason: reason,
        );
      }
    } finally {
      _markStreamingEnd();
    }
  }

  /// Ensure welcome message exists
  void _ensureWelcomeMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final messages = _state.messages.toList();
    final existingIndex = messages.indexWhere((m) => m.id == 'welcome');

    if (existingIndex >= 0) {
      // Update existing welcome message
      messages[existingIndex] = messages[existingIndex].copyWith(
        payload: TextPayload(content: trimmed),
      );
    } else {
      // Insert welcome message at the beginning
      messages.insert(
        0,
        ChatMessage(
          id: 'welcome',
          role: 'agent',
          payload: TextPayload(content: trimmed),
          time: DateTime.now(),
        ),
      );
    }

    _updateState(_state.copyWith(messages: messages));
  }

  /// Increment unread count
  void _incrementUnreadCount() {
    final newCount = _state.unreadCount + 1;
    _updateState(_state.copyWith(unreadCount: newCount));
    _unreadCountController.add(newCount);
  }

  /// Clear unread count
  void clearUnreadCount() {
    _updateState(_state.copyWith(unreadCount: 0));
    _unreadCountController.add(0);
  }

  /// Retry sending a failed message
  Future<void> retryMessage(String messageId) async {
    final message = _state.messages.firstWhere(
      (m) => m.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );

    if (message.role != 'user') return;

    updateMessageStatus(messageId, MessageStatus.sending);

    try {
      await _imService.sendPayload(message.payload.toJson(),
          clientMsgNo: message.clientMsgNo);
      updateMessageStatus(messageId, MessageStatus.sent);

      // Retry completion
      String content = '';
      if (message.payload is TextPayload) {
        content = (message.payload as TextPayload).content;
      } else if (message.payload is FilePayload) {
        content = '[File] ${(message.payload as FilePayload).name}';
      } else if (message.payload is ImagePayload) {
        content = '[Image]';
      }

      try {
        await sendCompletion(content);
      } catch (e) {
        debugPrint('[ChatProvider] Retry completion error: $e');
      }
    } catch (e) {
      updateMessageStatus(messageId, MessageStatus.failed);
    }
  }

  /// Remove a message
  void removeMessage(String messageId) {
    final messages =
        _state.messages.where((m) => m.id != messageId).toList();
    _updateState(_state.copyWith(messages: messages));
  }

  /// Add a message to the list
  void addMessage(ChatMessage message) {
    final messages = [..._state.messages, message];
    _updateState(_state.copyWith(messages: messages));
  }

  /// Update message upload progress
  void updateMessageProgress(String messageId, int progress) {
    final messages = _state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(uploadProgress: progress);
      }
      return m;
    }).toList();
    _updateState(_state.copyWith(messages: messages));
  }

  /// Update message payload
  void updateMessagePayload(String messageId, MessagePayload payload) {
    final messages = _state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(payload: payload, uploadProgress: null);
      }
      return m;
    }).toList();
    _updateState(_state.copyWith(messages: messages));
  }

  /// Update message with upload error
  void updateMessageUploadError(String messageId, String error) {
    final messages = _state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          status: MessageStatus.failed,
          uploadError: error,
        );
      }
      return m;
    }).toList();
    _updateState(_state.copyWith(messages: messages));
  }

  /// Generate client message number
  String _generateClientMsgNo() {
    return 'cmn-${DateTime.now().millisecondsSinceEpoch}-${_randomString(6)}';
  }

  /// Generate random string
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[(DateTime.now().microsecond + index) % chars.length],
    ).join();
  }

  /// Retry an operation with exponential backoff
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    String operationName = 'Operation',
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          debugPrint('[$operationName] Failed after $maxRetries attempts: $e');
          rethrow;
        }
        // Exponential backoff: 1s, 2s, 4s...
        final delay = Duration(seconds: 1 << (attempt - 1));
        debugPrint('[$operationName] Attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
      }
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _unreadCountController.close();
    _connectionStatusController.close();
    _imService.removeMessageListener(_onMessageReceived);
    _imService.removeStatusListener(_onStatusChanged);
    _imService.removeCustomEventListener(_onCustomEvent);
    _uploadController.dispose();
    super.dispose();
  }

  /// Pause or clean up UI-only listeners
  void onUIClosed() {
    // Optional: Cancel heavy UI-only tasks if any
  }
}


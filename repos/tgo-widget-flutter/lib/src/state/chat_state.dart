import '../models/message.dart';
import '../models/api_types.dart';
import '../tgo_widget_impl.dart';

/// Immutable state for the chat
class ChatState {
  /// List of messages
  final List<ChatMessage> messages;

  /// Connection status
  final ConnectionStatus connectionStatus;

  /// Whether currently initializing
  final bool isInitializing;

  /// Error message if any
  final String? error;

  /// History loading state
  final bool historyLoading;

  /// Whether there are more history messages
  final bool historyHasMore;

  /// History loading error
  final String? historyError;

  /// Earliest message sequence number (for pagination)
  final int? earliestSeq;

  /// User's UID
  final String? myUid;

  /// Platform Open ID
  final String? platformOpenId;

  /// Channel ID
  final String? channelId;

  /// Channel type
  final int? channelType;

  /// Staff info cache
  final Map<String, StaffInfo> staffInfoCache;

  /// Whether AI is streaming
  final bool isStreaming;

  /// Whether stream is being cancelled
  final bool streamCanceling;

  /// Current streaming message's client message number
  final String? streamingClientMsgNo;

  /// Unread message count
  final int unreadCount;

  const ChatState({
    this.messages = const [],
    this.connectionStatus = ConnectionStatus.disconnected,
    this.isInitializing = false,
    this.error,
    this.historyLoading = false,
    this.historyHasMore = true,
    this.historyError,
    this.earliestSeq,
    this.myUid,
    this.platformOpenId,
    this.channelId,
    this.channelType,
    this.staffInfoCache = const {},
    this.isStreaming = false,
    this.streamCanceling = false,
    this.streamingClientMsgNo,
    this.unreadCount = 0,
  });

  /// Create a copy with updated fields
  ChatState copyWith({
    List<ChatMessage>? messages,
    ConnectionStatus? connectionStatus,
    bool? isInitializing,
    String? error,
    bool? historyLoading,
    bool? historyHasMore,
    String? historyError,
    int? earliestSeq,
    String? myUid,
    String? platformOpenId,
    String? channelId,
    int? channelType,
    Map<String, StaffInfo>? staffInfoCache,
    bool? isStreaming,
    bool? streamCanceling,
    String? streamingClientMsgNo,
    int? unreadCount,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
      historyLoading: historyLoading ?? this.historyLoading,
      historyHasMore: historyHasMore ?? this.historyHasMore,
      historyError: historyError ?? this.historyError,
      earliestSeq: earliestSeq ?? this.earliestSeq,
      myUid: myUid ?? this.myUid,
      platformOpenId: platformOpenId ?? this.platformOpenId,
      channelId: channelId ?? this.channelId,
      channelType: channelType ?? this.channelType,
      staffInfoCache: staffInfoCache ?? this.staffInfoCache,
      isStreaming: isStreaming ?? this.isStreaming,
      streamCanceling: streamCanceling ?? this.streamCanceling,
      streamingClientMsgNo: streamingClientMsgNo ?? this.streamingClientMsgNo,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Clear error
  ChatState clearError() {
    return ChatState(
      messages: messages,
      connectionStatus: connectionStatus,
      isInitializing: isInitializing,
      error: null,
      historyLoading: historyLoading,
      historyHasMore: historyHasMore,
      historyError: historyError,
      earliestSeq: earliestSeq,
      myUid: myUid,
      platformOpenId: platformOpenId,
      channelId: channelId,
      channelType: channelType,
      staffInfoCache: staffInfoCache,
      isStreaming: isStreaming,
      streamCanceling: streamCanceling,
      streamingClientMsgNo: streamingClientMsgNo,
      unreadCount: unreadCount,
    );
  }
}


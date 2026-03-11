/// Message status for transient states
enum MessageStatus {
  /// Message is being uploaded (file/image)
  uploading,

  /// Message is being sent
  sending,

  /// Message sent successfully
  sent,

  /// Message send failed
  failed,
}

/// Message payload types
enum MessageType {
  /// Text message (type: 1)
  text(1),

  /// Image message (type: 2)
  image(2),

  /// File message (type: 3)
  file(3),

  /// Mixed message with text and images (type: 12)
  mixed(12),

  /// Command message (type: 99)
  command(99),

  /// AI loading indicator (type: 100)
  aiLoading(100),

  /// System message (type: 1000-2000)
  system(1000);

  const MessageType(this.value);
  final int value;

  static MessageType fromValue(int value) {
    if (value >= 1000 && value <= 2000) return MessageType.system;
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Base class for message payloads
abstract class MessagePayload {
  MessageType get type;
  Map<String, dynamic> toJson();

  factory MessagePayload.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as int? ?? 1;
    final type = MessageType.fromValue(typeValue);

    switch (type) {
      case MessageType.text:
        return TextPayload.fromJson(json);
      case MessageType.image:
        return ImagePayload.fromJson(json);
      case MessageType.file:
        return FilePayload.fromJson(json);
      case MessageType.mixed:
        return MixedPayload.fromJson(json);
      case MessageType.command:
        return CommandPayload.fromJson(json);
      case MessageType.aiLoading:
        return AiLoadingPayload();
      case MessageType.system:
        return SystemPayload.fromJson(json);
    }
  }
}

/// Text message payload
class TextPayload implements MessagePayload {
  @override
  MessageType get type => MessageType.text;

  final String content;

  const TextPayload({required this.content});

  factory TextPayload.fromJson(Map<String, dynamic> json) {
    return TextPayload(content: json['content'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'type': 1, 'content': content};
}

/// Image message payload
class ImagePayload implements MessagePayload {
  @override
  MessageType get type => MessageType.image;

  final String url;
  final int width;
  final int height;

  const ImagePayload({
    required this.url,
    required this.width,
    required this.height,
  });

  factory ImagePayload.fromJson(Map<String, dynamic> json) {
    return ImagePayload(
      url: json['url'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 2,
        'url': url,
        'width': width,
        'height': height,
      };
}

/// File message payload
class FilePayload implements MessagePayload {
  @override
  MessageType get type => MessageType.file;

  final String content;
  final String url;
  final String name;
  final int size;

  const FilePayload({
    required this.content,
    required this.url,
    required this.name,
    required this.size,
  });

  factory FilePayload.fromJson(Map<String, dynamic> json) {
    return FilePayload(
      content: json['content'] as String? ?? '[File]',
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 3,
        'content': content,
        'url': url,
        'name': name,
        'size': size,
      };
}

/// Mixed message with text, images, and optional file
class MixedPayload implements MessagePayload {
  @override
  MessageType get type => MessageType.mixed;

  final String content;
  final List<ImageInfo> images;
  final FileInfo? file;

  const MixedPayload({
    required this.content,
    required this.images,
    this.file,
  });

  factory MixedPayload.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as List<dynamic>? ?? [];
    final images = imagesJson
        .where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => ImageInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    FileInfo? file;
    if (json['file'] != null && json['file'] is Map<String, dynamic>) {
      file = FileInfo.fromJson(json['file'] as Map<String, dynamic>);
    }

    return MixedPayload(
      content: json['content'] as String? ?? '',
      images: images,
      file: file,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 12,
        'content': content,
        'images': images.map((e) => e.toJson()).toList(),
        if (file != null) 'file': file!.toJson(),
      };
}

/// Image info for mixed messages
class ImageInfo {
  final String url;
  final int width;
  final int height;

  const ImageInfo({
    required this.url,
    required this.width,
    required this.height,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      url: json['url'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'width': width,
        'height': height,
      };
}

/// File info for mixed messages
class FileInfo {
  final String url;
  final String name;
  final int size;

  const FileInfo({
    required this.url,
    required this.name,
    required this.size,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'name': name,
        'size': size,
      };
}

/// Command message payload
class CommandPayload implements MessagePayload {
  @override
  MessageType get type => MessageType.command;

  final String cmd;
  final Map<String, dynamic> param;

  const CommandPayload({
    required this.cmd,
    required this.param,
  });

  factory CommandPayload.fromJson(Map<String, dynamic> json) {
    return CommandPayload(
      cmd: json['cmd'] as String? ?? '',
      param: json['param'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 99,
        'cmd': cmd,
        'param': param,
      };
}

/// AI loading indicator payload
class AiLoadingPayload implements MessagePayload {
  @override
  MessageType get type => MessageType.aiLoading;

  const AiLoadingPayload();

  @override
  Map<String, dynamic> toJson() => {'type': 100};
}

/// System message payload (type 1000-2000)
class SystemPayload implements MessagePayload {
  @override
  MessageType get type => MessageType.system;

  final int typeValue;
  final String content;
  final List<SystemMessageExtra>? extra;

  const SystemPayload({
    required this.typeValue,
    required this.content,
    this.extra,
  });

  factory SystemPayload.fromJson(Map<String, dynamic> json) {
    final extraJson = json['extra'] as List<dynamic>?;
    final extra = extraJson
        ?.where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => SystemMessageExtra.fromJson(e as Map<String, dynamic>))
        .toList();

    return SystemPayload(
      typeValue: json['type'] as int? ?? 1000,
      content: json['content'] as String? ?? '',
      extra: extra,
    );
  }

  /// Format content by replacing {0}, {1}, etc. with extra data
  String get formattedContent {
    if (extra == null || extra!.isEmpty) return content;

    var result = content;
    for (var i = 0; i < extra!.length; i++) {
      final item = extra![i];
      final name = item.name ?? item.uid ?? '';
      result = result.replaceAll('{$i}', name);
    }
    return result;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': typeValue,
        'content': content,
        if (extra != null) 'extra': extra!.map((e) => e.toJson()).toList(),
      };
}

/// Extra data for system messages
class SystemMessageExtra {
  final String? uid;
  final String? name;
  final Map<String, dynamic>? additionalData;

  const SystemMessageExtra({
    this.uid,
    this.name,
    this.additionalData,
  });

  factory SystemMessageExtra.fromJson(Map<String, dynamic> json) {
    return SystemMessageExtra(
      uid: json['uid'] as String?,
      name: json['name'] as String?,
      additionalData: Map<String, dynamic>.from(json)
        ..remove('uid')
        ..remove('name'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (uid != null) 'uid': uid,
        if (name != null) 'name': name,
        ...?additionalData,
      };
}

/// Chat message model
class ChatMessage {
  /// Unique message ID
  final String id;

  /// Message role: 'user' or 'agent'
  final String role;

  /// Message payload
  final MessagePayload payload;

  /// Message timestamp
  final DateTime time;

  /// Message sequence number (from server)
  final int? messageSeq;

  /// Client message number (for tracking)
  final String? clientMsgNo;

  /// Sender user ID
  final String? fromUid;

  /// Channel ID
  final String? channelId;

  /// Channel type
  final int? channelType;

  /// Streaming data (for AI responses)
  final String? streamData;

  /// Message status
  final MessageStatus? status;

  /// Upload progress (0-100)
  final int? uploadProgress;

  /// Upload error message
  final String? uploadError;

  /// Error message (from AI)
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.payload,
    required this.time,
    this.messageSeq,
    this.clientMsgNo,
    this.fromUid,
    this.channelId,
    this.channelType = 251,
    this.streamData,
    this.status,
    this.uploadProgress,
    this.uploadError,
    this.errorMessage,
  });

  bool get isUser => role == 'user';
  bool get isAgent => role == 'agent';
  bool get isStreaming => streamData != null && streamData!.isNotEmpty;
  bool get isSystemMessage =>
      payload.type == MessageType.system ||
      (payload is SystemPayload &&
          (payload as SystemPayload).typeValue >= 1000 &&
          (payload as SystemPayload).typeValue <= 2000);

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? role,
    MessagePayload? payload,
    DateTime? time,
    int? messageSeq,
    String? clientMsgNo,
    String? fromUid,
    String? channelId,
    int? channelType,
    String? streamData,
    MessageStatus? status,
    int? uploadProgress,
    String? uploadError,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      payload: payload ?? this.payload,
      time: time ?? this.time,
      messageSeq: messageSeq ?? this.messageSeq,
      clientMsgNo: clientMsgNo ?? this.clientMsgNo,
      fromUid: fromUid ?? this.fromUid,
      channelId: channelId ?? this.channelId,
      channelType: channelType ?? this.channelType,
      streamData: streamData ?? this.streamData,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadError: uploadError ?? this.uploadError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Clear stream data (finalize streaming)
  ChatMessage clearStreamData() {
    return ChatMessage(
      id: id,
      role: role,
      payload: streamData != null && streamData!.isNotEmpty
          ? TextPayload(content: streamData!)
          : payload,
      time: time,
      messageSeq: messageSeq,
      clientMsgNo: clientMsgNo,
      fromUid: fromUid,
      channelId: channelId,
      channelType: channelType,
      streamData: null,
      status: status,
      uploadProgress: uploadProgress,
      uploadError: uploadError,
      errorMessage: errorMessage,
    );
  }
}


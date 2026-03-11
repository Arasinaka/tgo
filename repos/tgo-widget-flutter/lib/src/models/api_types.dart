/// WuKongIM message from history sync API
class WuKongIMMessage {
  final Map<String, dynamic>? header;
  final int? setting;
  final int? messageId;
  final String? messageIdStr;
  final String? clientMsgNo;
  final int? messageSeq;
  final String? fromUid;
  final String? channelId;
  final int? channelType;
  final int? timestamp;
  final dynamic payload;
  final MessageSettingFlags? settingFlags;
  final int? end;
  final String? endReason;
  final String? streamData;
  final String? error;

  const WuKongIMMessage({
    this.header,
    this.setting,
    this.messageId,
    this.messageIdStr,
    this.clientMsgNo,
    this.messageSeq,
    this.fromUid,
    this.channelId,
    this.channelType,
    this.timestamp,
    this.payload,
    this.settingFlags,
    this.end,
    this.endReason,
    this.streamData,
    this.error,
  });

  factory WuKongIMMessage.fromJson(Map<String, dynamic> json) {
    return WuKongIMMessage(
      header: json['header'] as Map<String, dynamic>?,
      setting: json['setting'] as int?,
      messageId: json['message_id'] as int?,
      messageIdStr: json['message_id_str'] as String?,
      clientMsgNo: json['client_msg_no'] as String?,
      messageSeq: json['message_seq'] as int?,
      fromUid: json['from_uid'] as String?,
      channelId: json['channel_id'] as String?,
      channelType: json['channel_type'] as int?,
      timestamp: json['timestamp'] as int?,
      payload: json['payload'],
      settingFlags: json['setting_flags'] != null
          ? MessageSettingFlags.fromJson(
              json['setting_flags'] as Map<String, dynamic>)
          : null,
      end: json['end'] as int?,
      endReason: json['end_reason'] as String?,
      streamData: json['stream_data'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Message setting flags
class MessageSettingFlags {
  final bool? receipt;
  final bool? signal;
  final bool? noEncrypt;
  final bool? topic;
  final bool? stream;

  const MessageSettingFlags({
    this.receipt,
    this.signal,
    this.noEncrypt,
    this.topic,
    this.stream,
  });

  factory MessageSettingFlags.fromJson(Map<String, dynamic> json) {
    return MessageSettingFlags(
      receipt: json['receipt'] as bool?,
      signal: json['signal'] as bool?,
      noEncrypt: json['no_encrypt'] as bool?,
      topic: json['topic'] as bool?,
      stream: json['stream'] as bool?,
    );
  }
}

/// Message sync response
class MessageSyncResponse {
  final int startMessageSeq;
  final int endMessageSeq;
  final int more;
  final List<WuKongIMMessage> messages;

  const MessageSyncResponse({
    required this.startMessageSeq,
    required this.endMessageSeq,
    required this.more,
    required this.messages,
  });

  factory MessageSyncResponse.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesJson
        .where((e) => e != null && e is Map<String, dynamic>)
        .map((e) => WuKongIMMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    return MessageSyncResponse(
      startMessageSeq: json['start_message_seq'] as int? ?? 0,
      endMessageSeq: json['end_message_seq'] as int? ?? 0,
      more: json['more'] as int? ?? 0,
      messages: messages,
    );
  }
}

/// Channel info response
class ChannelInfo {
  final String? name;
  final String? avatar;
  final Map<String, dynamic>? extra;

  const ChannelInfo({
    this.name,
    this.avatar,
    this.extra,
  });

  factory ChannelInfo.fromJson(Map<String, dynamic> json) {
    return ChannelInfo(
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }
}

/// Staff info for display
class StaffInfo {
  final String name;
  final String? avatar;

  const StaffInfo({
    required this.name,
    this.avatar,
  });
}

/// Chat completion request
class ChatCompletionRequest {
  final String apiKey;
  final String message;
  final String fromUid;
  final String? channelId;
  final int? channelType;
  final bool wukongimOnly;
  final bool forwardUserMessageToWukongim;
  final bool stream;

  const ChatCompletionRequest({
    required this.apiKey,
    required this.message,
    required this.fromUid,
    this.channelId,
    this.channelType,
    this.wukongimOnly = true,
    this.forwardUserMessageToWukongim = false,
    this.stream = false,
  });

  Map<String, dynamic> toJson() => {
        'api_key': apiKey,
        'message': message,
        'from_uid': fromUid,
        if (channelId != null) 'channel_id': channelId,
        if (channelType != null) 'channel_type': channelType,
        'wukongim_only': wukongimOnly,
        'forward_user_message_to_wukongim': forwardUserMessageToWukongim,
        'stream': stream,
      };
}

/// Route response for WuKongIM WebSocket address
class RouteResponse {
  final String? wssAddr;
  final String? wsAddr;

  const RouteResponse({
    this.wssAddr,
    this.wsAddr,
  });

  factory RouteResponse.fromJson(Map<String, dynamic> json) {
    return RouteResponse(
      wssAddr: json['wss_addr'] as String?,
      wsAddr: json['ws_addr'] as String?,
    );
  }

  /// Get the best WebSocket address
  String? get bestAddr => wssAddr ?? wsAddr;
}

/// Upload file response
class UploadFileResponse {
  final String fileId;
  final String? fileName;
  final int? fileSize;

  const UploadFileResponse({
    required this.fileId,
    this.fileName,
    this.fileSize,
  });

  factory UploadFileResponse.fromJson(Map<String, dynamic> json) {
    return UploadFileResponse(
      fileId: json['file_id'] as String,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
    );
  }
}


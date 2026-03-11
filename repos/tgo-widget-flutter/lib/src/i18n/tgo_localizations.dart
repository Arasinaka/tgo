/// Simple localization support for TGO Widget
class TgoLocalizations {
  final String locale;

  const TgoLocalizations({this.locale = 'en'});

  /// Get localized string
  String get(String key) {
    final strings = locale == 'zh' ? _zhStrings : _enStrings;
    return strings[key] ?? key;
  }

  static const Map<String, String> _enStrings = {
    'sending': 'Sending...',
    'sent': 'Sent',
    'failed': 'Failed',
    'retry': 'Retry',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'uploading': 'Uploading',
    'upload_failed': 'Upload failed',
    'loading_history': 'Loading history...',
    'load_history_failed': 'Failed to load history',
    'no_more_messages': 'No more messages',
    'type_message': 'Type a message...',
    'send': 'Send',
    'attach': 'Attach',
    'emoji': 'Emoji',
    'interrupt': 'Stop',
    'just_now': 'Just now',
    'yesterday': 'Yesterday',
    'file_too_large': 'File too large (max {size}MB): {name}',
    'connection_error': 'Connection error',
    'auth_failed': 'Authentication failed',
    'network_error': 'Network error',
    'system_error': 'System error',
    'gallery': 'Gallery',
    'camera': 'Camera',
    'files': 'Files',
  };

  static const Map<String, String> _zhStrings = {
    'sending': '发送中...',
    'sent': '已发送',
    'failed': '发送失败',
    'retry': '重试',
    'delete': '删除',
    'cancel': '取消',
    'uploading': '上传中',
    'upload_failed': '上传失败',
    'loading_history': '加载历史消息...',
    'load_history_failed': '加载历史消息失败',
    'no_more_messages': '没有更多消息',
    'type_message': '输入消息...',
    'send': '发送',
    'attach': '附件',
    'emoji': '表情',
    'interrupt': '停止',
    'just_now': '刚刚',
    'yesterday': '昨天',
    'file_too_large': '文件过大（最大 {size}MB）：{name}',
    'connection_error': '连接错误',
    'auth_failed': '认证失败',
    'network_error': '网络错误',
    'system_error': '系统错误',
    'gallery': '相册',
    'camera': '相机',
    'files': '文件',
  };
}


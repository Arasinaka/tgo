import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/upload_service.dart';
import '../services/im_service.dart';
import 'chat_provider.dart';

/// Controller for file upload operations
class UploadController {
  final UploadService _uploadService;
  final IMService _imService;
  final ChatProvider _provider;

  // Track pending uploads
  final Map<String, CancelToken> _uploadTokens = {};
  final Map<String, File> _pendingFiles = {};

  UploadController({
    required UploadService uploadService,
    required IMService imService,
    required ChatProvider provider,
  })  : _uploadService = uploadService,
        _imService = imService,
        _provider = provider;

  /// Get image dimensions from file
  Future<ui.Image> _getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Get image dimensions from bytes
  Future<ui.Image> _getImageDimensionsFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Upload a file
  Future<void> uploadFile(File file) async {
    final channelId = _provider.state.channelId;
    final channelType = _provider.state.channelType;

    if (channelId == null || channelType == null) {
      throw Exception('Not initialized');
    }

    final isImage = _isImageFile(file.path);
    final clientMsgNo = _generateClientMsgNo();
    final messageId = 'u-up-${DateTime.now().millisecondsSinceEpoch}';

    // Create placeholder message
    final placeholder = ChatMessage(
      id: messageId,
      role: 'user',
      payload: TextPayload(
          content: isImage ? 'Uploading image...' : 'Uploading file...'),
      time: DateTime.now(),
      status: MessageStatus.uploading,
      uploadProgress: 0,
      clientMsgNo: clientMsgNo,
    );

    _provider.addMessage(placeholder);
    _pendingFiles[messageId] = file;

    final cancelToken = CancelToken();
    _uploadTokens[messageId] = cancelToken;

    try {
      // 1. 获取图片尺寸 (如果是图片)
      int width = 0;
      int height = 0;
      if (isImage) {
        try {
          final image = await _getImageDimensions(file);
          width = image.width;
          height = image.height;
        } catch (e) {
          debugPrint('[UploadController] Get image dimensions error: $e');
        }
      }

      // 2. 上传文件
      final response = await _uploadService.uploadFile(
        channelId: channelId,
        channelType: channelType,
        file: file,
        onProgress: (progress) {
          _provider.updateMessageProgress(messageId, progress);
        },
        cancelToken: cancelToken,
      );

      // Create message payload
      final fileUrl = _uploadService.makeFileUrl(response.fileId);
      MessagePayload payload;

      if (isImage) {
        payload = ImagePayload(
          url: fileUrl,
          width: width,
          height: height,
        );
      } else {
        payload = FilePayload(
          content: file.path.split('/').last,
          url: fileUrl,
          name: response.fileName ?? file.path.split('/').last,
          size: response.fileSize ?? await file.length(),
        );
      }

      // Update message with payload
      _provider.updateMessagePayload(messageId, payload);
      _provider.updateMessageStatus(messageId, MessageStatus.sending);

      // 3. 通过 IM 发送消息
      await _imService.sendPayload(payload.toJson(), clientMsgNo: clientMsgNo);

      // 发送成功后，更新状态为 sent
      _provider.updateMessageStatus(messageId, MessageStatus.sent);

      // 4. 再调用 completion 接口
      try {
        String content = '';
        if (payload is TextPayload) {
          content = payload.content;
        } else if (payload is FilePayload) {
          content = '[File] ${payload.name}';
        } else if (payload is ImagePayload) {
          content = '[Image]';
        }
        await _provider.sendCompletion(content);
      } catch (e) {
        debugPrint('[UploadController] Completion error (non-fatal): $e');
      }

      // Cleanup
      _uploadTokens.remove(messageId);
      _pendingFiles.remove(messageId);
    } catch (e) {
      debugPrint('[UploadController] Upload error: $e');

      _uploadTokens.remove(messageId);

      final isCancelled =
          e is DioException && e.type == DioExceptionType.cancel;

      _provider.updateMessageUploadError(
        messageId,
        isCancelled ? 'Cancelled' : e.toString(),
      );
    }
  }

  /// Upload bytes (for web platform)
  Future<void> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final channelId = _provider.state.channelId;
    final channelType = _provider.state.channelType;

    if (channelId == null || channelType == null) {
      throw Exception('Not initialized');
    }

    final isImage = mimeType?.startsWith('image/') ?? false;
    final clientMsgNo = _generateClientMsgNo();
    final messageId = 'u-up-${DateTime.now().millisecondsSinceEpoch}';

    // Create placeholder message
    final placeholder = ChatMessage(
      id: messageId,
      role: 'user',
      payload: TextPayload(
          content: isImage ? 'Uploading image...' : 'Uploading file...'),
      time: DateTime.now(),
      status: MessageStatus.uploading,
      uploadProgress: 0,
      clientMsgNo: clientMsgNo,
    );

    _provider.addMessage(placeholder);

    final cancelToken = CancelToken();
    _uploadTokens[messageId] = cancelToken;

    try {
      // 1. 获取图片尺寸 (如果是图片)
      int width = 0;
      int height = 0;
      if (isImage) {
        try {
          final image = await _getImageDimensionsFromBytes(bytes);
          width = image.width;
          height = image.height;
        } catch (e) {
          debugPrint('[UploadController] Get image dimensions error: $e');
        }
      }

      // 2. 上传
      final response = await _uploadService.uploadBytes(
        channelId: channelId,
        channelType: channelType,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        onProgress: (progress) {
          _provider.updateMessageProgress(messageId, progress);
        },
        cancelToken: cancelToken,
      );

      final fileUrl = _uploadService.makeFileUrl(response.fileId);
      MessagePayload payload;

      if (isImage) {
        payload = ImagePayload(
          url: fileUrl,
          width: width,
          height: height,
        );
      } else {
        payload = FilePayload(
          content: fileName,
          url: fileUrl,
          name: response.fileName ?? fileName,
          size: response.fileSize ?? bytes.length,
        );
      }

      _provider.updateMessagePayload(messageId, payload);
      _provider.updateMessageStatus(messageId, MessageStatus.sending);

      // 3. 通过 IM 发送消息
      await _imService.sendPayload(payload.toJson(), clientMsgNo: clientMsgNo);

      // 发送成功后，更新状态为 sent
      _provider.updateMessageStatus(messageId, MessageStatus.sent);

      // 4. 再调用 completion 接口
      try {
        String content = '';
        if (payload is TextPayload) {
          content = payload.content;
        } else if (payload is FilePayload) {
          content = '[File] ${payload.name}';
        } else if (payload is ImagePayload) {
          content = '[Image]';
        }
        await _provider.sendCompletion(content);
      } catch (e) {
        debugPrint('[UploadController] Completion error (non-fatal): $e');
      }

      _uploadTokens.remove(messageId);
    } catch (e) {
      debugPrint('[UploadController] Upload bytes error: $e');
      _uploadTokens.remove(messageId);

      final isCancelled =
          e is DioException && e.type == DioExceptionType.cancel;

      _provider.updateMessageUploadError(
        messageId,
        isCancelled ? 'Cancelled' : e.toString(),
      );
    }
  }

  /// Cancel an upload
  void cancelUpload(String messageId) {
    final token = _uploadTokens[messageId];
    if (token != null && !token.isCancelled) {
      token.cancel();
      _uploadTokens.remove(messageId);
    }
    _provider.updateMessageUploadError(messageId, 'Cancelled');
  }

  /// Retry a failed upload
  Future<void> retryUpload(String messageId) async {
    final file = _pendingFiles[messageId];
    if (file != null) {
      // Remove old message and re-upload
      _provider.removeMessage(messageId);
      await uploadFile(file);
    }
  }

  bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  String _generateClientMsgNo() {
    return 'um-${DateTime.now().millisecondsSinceEpoch}-${_randomString(6)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
      length,
      (index) => chars[(DateTime.now().microsecond + index) % chars.length],
    ).join();
  }

  void dispose() {
    for (final token in _uploadTokens.values) {
      if (!token.isCancelled) {
        token.cancel();
      }
    }
    _uploadTokens.clear();
    _pendingFiles.clear();
  }
}



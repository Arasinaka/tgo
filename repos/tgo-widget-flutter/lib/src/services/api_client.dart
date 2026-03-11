import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 统一的 API 客户端封装
class ApiClient {
  static Dio createDio({
    required String apiBase,
    String? apiKey,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: apiBase.endsWith('/') ? apiBase : '$apiBase/',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        if (apiKey != null) 'X-Platform-API-Key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加日志拦截器
    dio.interceptors.add(TgoApiLogger());

    return dio;
  }
}

/// 接口日志拦截器
class TgoApiLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n--- [API Request] ---');
      debugPrint('URL: ${options.method} ${options.uri}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('Query: ${options.queryParameters}');
      }
      if (options.data != null) {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          debugPrint('Body (FormData): ${formData.fields}');
        } else {
          debugPrint('Body: ${options.data}');
        }
      }
      debugPrint('Headers: ${options.headers}');
      debugPrint('---------------------\n');
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n--- [API Response] (${response.statusCode}) ---');
      debugPrint('URL: ${response.requestOptions.uri}');
      debugPrint('Data: ${response.data}');
      debugPrint('----------------------\n');
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('\n--- [API Error] ---');
      debugPrint('URL: ${err.requestOptions.uri}');
      debugPrint('Type: ${err.type}');
      debugPrint('Message: ${err.message}');
      if (err.response != null) {
        debugPrint('Status: ${err.response?.statusCode}');
        debugPrint('Data: ${err.response?.data}');
      }
      debugPrint('-------------------\n');
    }
    return super.onError(err, handler);
  }
}


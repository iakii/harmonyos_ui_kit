import 'package:dio/dio.dart';
import '../error/app_exception.dart';

/// 将 [DioException] 映射到 [AppException] 密封类。
AppException mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => TimeoutException(
      '请求超时：${e.message}',
      stackTrace: e.stackTrace,
    ),

    DioExceptionType.badResponse => _mapStatusCode(e),

    DioExceptionType.cancel => NetworkException(
      '请求已取消',
      stackTrace: e.stackTrace,
    ),

    DioExceptionType.connectionError => NetworkException(
      '无网络连接',
      stackTrace: e.stackTrace,
    ),

    DioExceptionType.unknown ||
    DioExceptionType.badCertificate => UnknownException(
      '未知错误：${e.message}',
      stackTrace: e.stackTrace,
      originalError: e.error,
    ),
    DioExceptionType.transformTimeout => throw UnimplementedError(),
  };
}

AppException _mapStatusCode(DioException e) {
  final statusCode = e.response?.statusCode;
  final message = _extractMessage(e.response?.data);

  return switch (statusCode) {
    401 || 403 => AuthException(
      message ?? '认证失败 (HTTP $statusCode)',
      code: '$statusCode',
      stackTrace: e.stackTrace,
    ),
    404 => NetworkException(
      message ?? '资源不存在',
      statusCode: 404,
      stackTrace: e.stackTrace,
    ),
    422 || 400 => NetworkException(
      message ?? '请求参数错误',
      statusCode: statusCode,
      stackTrace: e.stackTrace,
    ),
    500 || 502 || 503 => NetworkException(
      message ?? '服务器错误 (HTTP $statusCode)',
      statusCode: statusCode,
      stackTrace: e.stackTrace,
    ),
    _ => NetworkException(
      message ?? 'HTTP 错误 $statusCode',
      statusCode: statusCode,
      stackTrace: e.stackTrace,
    ),
  };
}

/// 尝试从响应体中提取错误消息
String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['message'] as String? ?? data['msg'] as String?;
  }
  return null;
}

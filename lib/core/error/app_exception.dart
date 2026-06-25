/// 应用异常密封类体系。
///
/// 使用 Dart 3 sealed class 实现，配合 switch 模式匹配进行穷举处理。
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (code: $code)' : ''}';
}

/// 网络异常（HTTP 错误、无连接等）
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.stackTrace, this.statusCode});

  final int? statusCode;
}

/// 认证异常（401/403）
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.stackTrace});
}

/// 超时异常
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.code, super.stackTrace});
}

/// 数据解析异常
class ParseException extends AppException {
  const ParseException(super.message, {super.code, super.stackTrace, this.rawData});

  final String? rawData;
}

/// 未知异常
class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.stackTrace, this.originalError});

  final Object? originalError;
}

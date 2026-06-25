import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 网络请求日志拦截器 —— 使用 [Logger] 输出格式化日志。
class AppLogInterceptor extends Interceptor {
  AppLogInterceptor({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d(
      '🌐 ${options.method} ${options.uri}\n'
      'Headers: ${_formatHeaders(options.headers)}\n'
      'Query: ${options.queryParameters}\n'
      'Body: ${_formatBody(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      '✅ ${response.statusCode} ${response.requestOptions.uri}\n'
      'Body: ${_formatBody(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '❌ ${err.type} ${err.requestOptions.uri}\n'
      'Message: ${err.message}\n'
      'Response: ${_formatBody(err.response?.data)}',
    );
    handler.next(err);
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    // 隐藏敏感信息
    final safe = Map<String, dynamic>.from(headers);
    if (safe.containsKey('Authorization')) {
      safe['Authorization'] = '***';
    }
    return safe.toString();
  }

  String _formatBody(dynamic data) {
    if (data == null) return 'null';
    final str = data.toString();
    // 截断过长内容
    return str.length > 500 ? '${str.substring(0, 500)}...' : str;
  }
}

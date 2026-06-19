import 'package:dio/dio.dart';

/// Token 注入拦截器 —— 在请求头中自动添加 Authorization。
///
/// 使用方式：
/// ```dart
/// final interceptor = AuthInterceptor();
/// interceptor.updateToken('your-token');
/// ```
class AuthInterceptor extends Interceptor {
  String? _cachedToken;

  /// 更新缓存的 Token（登录成功后调用）。
  void updateToken(String? token) {
    _cachedToken = token;
  }

  /// 清除 Token（登出时调用）。
  void clearToken() {
    _cachedToken = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_cachedToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token 过期或无效，清除缓存
      _cachedToken = null;
    }
    handler.next(err);
  }
}

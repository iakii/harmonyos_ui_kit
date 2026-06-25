import 'package:dio/dio.dart';
import '../../error/app_exception.dart';
import '../api_exception.dart';

/// 错误拦截器 —— 在 Dio 错误到达调用方之前，将其转换为 [AppException]。
///
/// 转换后的 AppException 存储在 `DioException.error` 中，调用方可以安全地
/// 将其取出并使用。
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 如果已有 AppException（可能来自其他拦截器），直接放行
    if (err.error is AppException) {
      handler.next(err);
      return;
    }

    final appException = mapDioException(err);

    handler.reject(
      DioException(
        type: err.type,
        requestOptions: err.requestOptions,
        response: err.response,
        error: appException,
        message: appException.message,
        stackTrace: err.stackTrace,
      ),
    );
  }
}

import 'package:dio/dio.dart';
import '../error/app_exception.dart';
import '../error/result.dart';

/// 数据仓库基类 —— 提供通用的错误处理模式。
///
/// 使用方式：
/// ```dart
/// class UserRepository extends BaseRepository {
///   Future<Result<User>> getUser(int id) => safeCall(() => dio.get('/users/$id'));
/// }
/// ```
abstract class BaseRepository {
  const BaseRepository(this.dio);

  final Dio dio;

  /// 安全执行 Dio 请求，自动捕获异常并包装为 [Result]。
  ///
  /// [call] 返回 [Response]，[transform] 将响应数据转换为目标类型。
  Future<Result<T>> safeCall<T>(
    Future<Response> Function() call, {
    T Function(dynamic data)? transform,
  }) async {
    try {
      final response = await call();
      final data = transform != null ? transform(response.data) : response.data as T;
      return Success(data);
    } on DioException catch (e) {
      // 如果拦截器已将 error 转为 AppException，取出
      final appException = e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Unknown network error');
      return Failure(appException);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }
}

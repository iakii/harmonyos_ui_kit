import 'app_exception.dart';

/// 泛型结果类型 —— 表示操作成功或失败。
///
/// ```dart
/// final result = await someOperation();
/// switch (result) {
///   case Success(:final data) => print('Got: $data'),
///   case Failure(:final error) => print('Error: $error'),
/// }
/// ```
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final AppException error;
}

/// 便捷扩展方法
extension ResultExtension<T> on Result<T> {
  /// 模式匹配处理成功/失败
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }

  /// 成功时返回 data，否则 null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    _ => null,
  };

  /// 失败时返回 error，否则 null
  AppException? get errorOrNull => switch (this) {
    Failure(:final error) => error,
    _ => null,
  };

  /// 是否成功
  bool get isSuccess => switch (this) {
    Success() => true,
    _ => false,
  };

  /// 是否失败
  bool get isFailure => switch (this) {
    Failure() => true,
    _ => false,
  };
}

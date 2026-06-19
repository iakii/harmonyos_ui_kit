import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import '../models/app_exception.dart';

/// 通用的 AsyncValue 三态渲染组件。
///
/// 自动处理 loading / error / data 三种状态，与 Riverpod 的 [AsyncValue] 配合使用。
///
/// 使用方式：
/// ```dart
/// final asyncData = ref.watch(someFutureProvider);
/// AsyncValueWidget(
///   value: asyncData,
///   data: (data) => Text('$data'),
/// );
/// ```
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(AppException error, VoidCallback retry)? error;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const Center(child: HosLoading()),
      error: (err, stackTrace) {
        final appException = err is AppException
            ? err
            : UnknownException(err.toString(), stackTrace: stackTrace);

        final errorBuilder = error;
        if (errorBuilder != null) {
          return errorBuilder(appException, () => value.asData == null);
        }
        return _DefaultErrorWidget(exception: appException);
      },
      data: (data) => this.data(data),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.exception});

  final AppException exception;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (exception) {
          NetworkException(:final message) =>
            HosErrorState(message: message, onRetry: () {}),
          TimeoutException(:final message) =>
            HosErrorState(message: message, onRetry: () {}),
          AuthException(:final message) =>
            HosErrorState(message: message, onRetry: null),
          _ => HosErrorState(message: exception.message, onRetry: () {}),
        },
      ),
    );
  }
}

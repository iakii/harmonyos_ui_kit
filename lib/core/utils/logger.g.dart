// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Logger 实例的 Riverpod Provider。
///
/// 可通过此 Provider 注入 Logger，便于测试时替换为 mock 实现：
/// ```dart
/// ref.read(loggerProvider).d('message');
/// ```

@ProviderFor(logger)
final loggerProvider = LoggerProvider._();

/// Logger 实例的 Riverpod Provider。
///
/// 可通过此 Provider 注入 Logger，便于测试时替换为 mock 实现：
/// ```dart
/// ref.read(loggerProvider).d('message');
/// ```

final class LoggerProvider extends $FunctionalProvider<Logger, Logger, Logger>
    with $Provider<Logger> {
  /// Logger 实例的 Riverpod Provider。
  ///
  /// 可通过此 Provider 注入 Logger，便于测试时替换为 mock 实现：
  /// ```dart
  /// ref.read(loggerProvider).d('message');
  /// ```
  LoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerHash();

  @$internal
  @override
  $ProviderElement<Logger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Logger create(Ref ref) {
    return logger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Logger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Logger>(value),
    );
  }
}

String _$loggerHash() => r'6b445dd746664b88535f51173b1f44d140d659d3';

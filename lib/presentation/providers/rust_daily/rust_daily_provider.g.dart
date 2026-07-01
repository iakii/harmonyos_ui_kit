// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rust_daily_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rust Daily 数据 Provider。
///
/// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
/// 经由 Repository 完成 HTTP 请求和 HTML 解析。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容

@ProviderFor(RustDaily)
final rustDailyProvider = RustDailyFamily._();

/// Rust Daily 数据 Provider。
///
/// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
/// 经由 Repository 完成 HTTP 请求和 HTML 解析。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
final class RustDailyProvider
    extends $NotifierProvider<RustDaily, RustDailyPageData> {
  /// Rust Daily 数据 Provider。
  ///
  /// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
  /// 经由 Repository 完成 HTTP 请求和 HTML 解析。
  /// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
  ///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
  /// - type == "detail" 时直接获取 `div.detail-body` 内容
  RustDailyProvider._({
    required RustDailyFamily super.from,
    required RustDailyParams super.argument,
  }) : super(
         retry: null,
         name: r'rustDailyProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rustDailyHash();

  @override
  String toString() {
    return r'rustDailyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RustDaily create() => RustDaily();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RustDailyPageData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RustDailyPageData>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RustDailyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rustDailyHash() => r'5203620f1a5d98a86aa28c09ae61f45c1bc34230';

/// Rust Daily 数据 Provider。
///
/// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
/// 经由 Repository 完成 HTTP 请求和 HTML 解析。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容

final class RustDailyFamily extends $Family
    with
        $ClassFamilyOverride<
          RustDaily,
          RustDailyPageData,
          RustDailyPageData,
          RustDailyPageData,
          RustDailyParams
        > {
  RustDailyFamily._()
    : super(
        retry: null,
        name: r'rustDailyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Rust Daily 数据 Provider。
  ///
  /// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
  /// 经由 Repository 完成 HTTP 请求和 HTML 解析。
  /// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
  ///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
  /// - type == "detail" 时直接获取 `div.detail-body` 内容

  RustDailyProvider call(RustDailyParams params) =>
      RustDailyProvider._(argument: params, from: this);

  @override
  String toString() => r'rustDailyProvider';
}

/// Rust Daily 数据 Provider。
///
/// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
/// 经由 Repository 完成 HTTP 请求和 HTML 解析。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容

abstract class _$RustDaily extends $Notifier<RustDailyPageData> {
  late final _$args = ref.$arg as RustDailyParams;
  RustDailyParams get params => _$args;

  RustDailyPageData build(RustDailyParams params);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RustDailyPageData, RustDailyPageData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RustDailyPageData, RustDailyPageData>,
              RustDailyPageData,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

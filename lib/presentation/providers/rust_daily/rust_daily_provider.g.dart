// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rust_daily_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$rustDailyHash() => r'58a72ed50e42f39a07322903871c9832ffc8e74c';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$RustDaily
    extends BuildlessAutoDisposeNotifier<RustDailyPageData> {
  late final RustDailyParams params;

  RustDailyPageData build(RustDailyParams params);
}

/// Rust Daily 数据 Provider。
///
/// 根据 [url]、[type] 获取并解析 HTML。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
///
/// Copied from [RustDaily].
@ProviderFor(RustDaily)
const rustDailyProvider = RustDailyFamily();

/// Rust Daily 数据 Provider。
///
/// 根据 [url]、[type] 获取并解析 HTML。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
///
/// Copied from [RustDaily].
class RustDailyFamily extends Family<RustDailyPageData> {
  /// Rust Daily 数据 Provider。
  ///
  /// 根据 [url]、[type] 获取并解析 HTML。
  /// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
  ///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
  /// - type == "detail" 时直接获取 `div.detail-body` 内容
  ///
  /// Copied from [RustDaily].
  const RustDailyFamily();

  /// Rust Daily 数据 Provider。
  ///
  /// 根据 [url]、[type] 获取并解析 HTML。
  /// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
  ///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
  /// - type == "detail" 时直接获取 `div.detail-body` 内容
  ///
  /// Copied from [RustDaily].
  RustDailyProvider call(RustDailyParams params) {
    return RustDailyProvider(params);
  }

  @override
  RustDailyProvider getProviderOverride(covariant RustDailyProvider provider) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'rustDailyProvider';
}

/// Rust Daily 数据 Provider。
///
/// 根据 [url]、[type] 获取并解析 HTML。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
///
/// Copied from [RustDaily].
class RustDailyProvider
    extends AutoDisposeNotifierProviderImpl<RustDaily, RustDailyPageData> {
  /// Rust Daily 数据 Provider。
  ///
  /// 根据 [url]、[type] 获取并解析 HTML。
  /// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
  ///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
  /// - type == "detail" 时直接获取 `div.detail-body` 内容
  ///
  /// Copied from [RustDaily].
  RustDailyProvider(RustDailyParams params)
    : this._internal(
        () => RustDaily()..params = params,
        from: rustDailyProvider,
        name: r'rustDailyProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$rustDailyHash,
        dependencies: RustDailyFamily._dependencies,
        allTransitiveDependencies: RustDailyFamily._allTransitiveDependencies,
        params: params,
      );

  RustDailyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final RustDailyParams params;

  @override
  RustDailyPageData runNotifierBuild(covariant RustDaily notifier) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(RustDaily Function() create) {
    return ProviderOverride(
      origin: this,
      override: RustDailyProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<RustDaily, RustDailyPageData>
  createElement() {
    return _RustDailyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RustDailyProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin RustDailyRef on AutoDisposeNotifierProviderRef<RustDailyPageData> {
  /// The parameter `params` of this provider.
  RustDailyParams get params;
}

class _RustDailyProviderElement
    extends AutoDisposeNotifierProviderElement<RustDaily, RustDailyPageData>
    with RustDailyRef {
  _RustDailyProviderElement(super.provider);

  @override
  RustDailyParams get params => (origin as RustDailyProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

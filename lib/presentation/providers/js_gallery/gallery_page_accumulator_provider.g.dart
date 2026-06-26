// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$galleryPageAccumulatorHash() =>
    r'734c23b3395dfe3ea9927595e740b987a500e4d7';

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

abstract class _$GalleryPageAccumulator
    extends BuildlessAutoDisposeAsyncNotifier<GalleryAccumulatorState> {
  late final String url;

  FutureOr<GalleryAccumulatorState> build(String url);
}

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。
///
/// Copied from [GalleryPageAccumulator].
@ProviderFor(GalleryPageAccumulator)
const galleryPageAccumulatorProvider = GalleryPageAccumulatorFamily();

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。
///
/// Copied from [GalleryPageAccumulator].
class GalleryPageAccumulatorFamily
    extends Family<AsyncValue<GalleryAccumulatorState>> {
  /// 图集分页累积 Provider（按 URL）。
  ///
  /// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
  /// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
  /// 不再需要在 Widget 中手动维护可变字段。
  ///
  /// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
  /// 状态自然清零，无需额外重置。
  ///
  /// Copied from [GalleryPageAccumulator].
  const GalleryPageAccumulatorFamily();

  /// 图集分页累积 Provider（按 URL）。
  ///
  /// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
  /// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
  /// 不再需要在 Widget 中手动维护可变字段。
  ///
  /// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
  /// 状态自然清零，无需额外重置。
  ///
  /// Copied from [GalleryPageAccumulator].
  GalleryPageAccumulatorProvider call(String url) {
    return GalleryPageAccumulatorProvider(url);
  }

  @override
  GalleryPageAccumulatorProvider getProviderOverride(
    covariant GalleryPageAccumulatorProvider provider,
  ) {
    return call(provider.url);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'galleryPageAccumulatorProvider';
}

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。
///
/// Copied from [GalleryPageAccumulator].
class GalleryPageAccumulatorProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          GalleryPageAccumulator,
          GalleryAccumulatorState
        > {
  /// 图集分页累积 Provider（按 URL）。
  ///
  /// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
  /// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
  /// 不再需要在 Widget 中手动维护可变字段。
  ///
  /// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
  /// 状态自然清零，无需额外重置。
  ///
  /// Copied from [GalleryPageAccumulator].
  GalleryPageAccumulatorProvider(String url)
    : this._internal(
        () => GalleryPageAccumulator()..url = url,
        from: galleryPageAccumulatorProvider,
        name: r'galleryPageAccumulatorProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$galleryPageAccumulatorHash,
        dependencies: GalleryPageAccumulatorFamily._dependencies,
        allTransitiveDependencies:
            GalleryPageAccumulatorFamily._allTransitiveDependencies,
        url: url,
      );

  GalleryPageAccumulatorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  FutureOr<GalleryAccumulatorState> runNotifierBuild(
    covariant GalleryPageAccumulator notifier,
  ) {
    return notifier.build(url);
  }

  @override
  Override overrideWith(GalleryPageAccumulator Function() create) {
    return ProviderOverride(
      origin: this,
      override: GalleryPageAccumulatorProvider._internal(
        () => create()..url = url,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    GalleryPageAccumulator,
    GalleryAccumulatorState
  >
  createElement() {
    return _GalleryPageAccumulatorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GalleryPageAccumulatorProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GalleryPageAccumulatorRef
    on AutoDisposeAsyncNotifierProviderRef<GalleryAccumulatorState> {
  /// The parameter `url` of this provider.
  String get url;
}

class _GalleryPageAccumulatorProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          GalleryPageAccumulator,
          GalleryAccumulatorState
        >
    with GalleryPageAccumulatorRef {
  _GalleryPageAccumulatorProviderElement(super.provider);

  @override
  String get url => (origin as GalleryPageAccumulatorProvider).url;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

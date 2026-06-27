// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchHash() => r'9a3c88149a95278c8024c86906f55dbd4bd54147';

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

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。
///
/// Copied from [search].
@ProviderFor(search)
const searchProvider = SearchFamily();

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。
///
/// Copied from [search].
class SearchFamily extends Family<AsyncValue<GalleryPageData>> {
  /// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
  ///
  /// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
  /// 由 [SearchPageAccumulator] 调用以累积分页数据。
  ///
  /// Copied from [search].
  const SearchFamily();

  /// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
  ///
  /// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
  /// 由 [SearchPageAccumulator] 调用以累积分页数据。
  ///
  /// Copied from [search].
  SearchProvider call({required String keyword, required int page}) {
    return SearchProvider(keyword: keyword, page: page);
  }

  @override
  SearchProvider getProviderOverride(covariant SearchProvider provider) {
    return call(keyword: provider.keyword, page: provider.page);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchProvider';
}

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。
///
/// Copied from [search].
class SearchProvider extends AutoDisposeFutureProvider<GalleryPageData> {
  /// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
  ///
  /// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
  /// 由 [SearchPageAccumulator] 调用以累积分页数据。
  ///
  /// Copied from [search].
  SearchProvider({required String keyword, required int page})
    : this._internal(
        (ref) => search(ref as SearchRef, keyword: keyword, page: page),
        from: searchProvider,
        name: r'searchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$searchHash,
        dependencies: SearchFamily._dependencies,
        allTransitiveDependencies: SearchFamily._allTransitiveDependencies,
        keyword: keyword,
        page: page,
      );

  SearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.keyword,
    required this.page,
  }) : super.internal();

  final String keyword;
  final int page;

  @override
  Override overrideWith(
    FutureOr<GalleryPageData> Function(SearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchProvider._internal(
        (ref) => create(ref as SearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        keyword: keyword,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GalleryPageData> createElement() {
    return _SearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchProvider &&
        other.keyword == keyword &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, keyword.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchRef on AutoDisposeFutureProviderRef<GalleryPageData> {
  /// The parameter `keyword` of this provider.
  String get keyword;

  /// The parameter `page` of this provider.
  int get page;
}

class _SearchProviderElement
    extends AutoDisposeFutureProviderElement<GalleryPageData>
    with SearchRef {
  _SearchProviderElement(super.provider);

  @override
  String get keyword => (origin as SearchProvider).keyword;
  @override
  int get page => (origin as SearchProvider).page;
}

String _$searchPageAccumulatorHash() =>
    r'6693c69f24625245d055f5afb8e229fc3cfe7465';

abstract class _$SearchPageAccumulator
    extends BuildlessAutoDisposeAsyncNotifier<GalleryAccumulatorState> {
  late final String keyword;

  FutureOr<GalleryAccumulatorState> build(String keyword);
}

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
///
/// Copied from [SearchPageAccumulator].
@ProviderFor(SearchPageAccumulator)
const searchPageAccumulatorProvider = SearchPageAccumulatorFamily();

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
///
/// Copied from [SearchPageAccumulator].
class SearchPageAccumulatorFamily
    extends Family<AsyncValue<GalleryAccumulatorState>> {
  /// 搜索分页累积 Provider（按 keyword）。
  ///
  /// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
  /// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
  /// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
  ///
  /// Copied from [SearchPageAccumulator].
  const SearchPageAccumulatorFamily();

  /// 搜索分页累积 Provider（按 keyword）。
  ///
  /// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
  /// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
  /// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
  ///
  /// Copied from [SearchPageAccumulator].
  SearchPageAccumulatorProvider call(String keyword) {
    return SearchPageAccumulatorProvider(keyword);
  }

  @override
  SearchPageAccumulatorProvider getProviderOverride(
    covariant SearchPageAccumulatorProvider provider,
  ) {
    return call(provider.keyword);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchPageAccumulatorProvider';
}

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
///
/// Copied from [SearchPageAccumulator].
class SearchPageAccumulatorProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          SearchPageAccumulator,
          GalleryAccumulatorState
        > {
  /// 搜索分页累积 Provider（按 keyword）。
  ///
  /// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
  /// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
  /// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
  ///
  /// Copied from [SearchPageAccumulator].
  SearchPageAccumulatorProvider(String keyword)
    : this._internal(
        () => SearchPageAccumulator()..keyword = keyword,
        from: searchPageAccumulatorProvider,
        name: r'searchPageAccumulatorProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$searchPageAccumulatorHash,
        dependencies: SearchPageAccumulatorFamily._dependencies,
        allTransitiveDependencies:
            SearchPageAccumulatorFamily._allTransitiveDependencies,
        keyword: keyword,
      );

  SearchPageAccumulatorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.keyword,
  }) : super.internal();

  final String keyword;

  @override
  FutureOr<GalleryAccumulatorState> runNotifierBuild(
    covariant SearchPageAccumulator notifier,
  ) {
    return notifier.build(keyword);
  }

  @override
  Override overrideWith(SearchPageAccumulator Function() create) {
    return ProviderOverride(
      origin: this,
      override: SearchPageAccumulatorProvider._internal(
        () => create()..keyword = keyword,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        keyword: keyword,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    SearchPageAccumulator,
    GalleryAccumulatorState
  >
  createElement() {
    return _SearchPageAccumulatorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPageAccumulatorProvider && other.keyword == keyword;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, keyword.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchPageAccumulatorRef
    on AutoDisposeAsyncNotifierProviderRef<GalleryAccumulatorState> {
  /// The parameter `keyword` of this provider.
  String get keyword;
}

class _SearchPageAccumulatorProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          SearchPageAccumulator,
          GalleryAccumulatorState
        >
    with SearchPageAccumulatorRef {
  _SearchPageAccumulatorProviderElement(super.provider);

  @override
  String get keyword => (origin as SearchPageAccumulatorProvider).keyword;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

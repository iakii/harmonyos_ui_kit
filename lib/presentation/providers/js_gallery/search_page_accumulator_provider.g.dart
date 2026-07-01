// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。

@ProviderFor(search)
final searchProvider = SearchFamily._();

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。

final class SearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<GalleryPageData>,
          GalleryPageData,
          FutureOr<GalleryPageData>
        >
    with $FutureModifier<GalleryPageData>, $FutureProvider<GalleryPageData> {
  /// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
  ///
  /// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
  /// 由 [SearchPageAccumulator] 调用以累积分页数据。
  SearchProvider._({
    required SearchFamily super.from,
    required ({String keyword, int page}) super.argument,
  }) : super(
         retry: null,
         name: r'searchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchHash();

  @override
  String toString() {
    return r'searchProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<GalleryPageData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GalleryPageData> create(Ref ref) {
    final argument = this.argument as ({String keyword, int page});
    return search(ref, keyword: argument.keyword, page: argument.page);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchHash() => r'9a3c88149a95278c8024c86906f55dbd4bd54147';

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。

final class SearchFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GalleryPageData>,
          ({String keyword, int page})
        > {
  SearchFamily._()
    : super(
        retry: null,
        name: r'searchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
  ///
  /// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
  /// 由 [SearchPageAccumulator] 调用以累积分页数据。

  SearchProvider call({required String keyword, required int page}) =>
      SearchProvider._(argument: (keyword: keyword, page: page), from: this);

  @override
  String toString() => r'searchProvider';
}

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。

@ProviderFor(SearchPageAccumulator)
final searchPageAccumulatorProvider = SearchPageAccumulatorFamily._();

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
final class SearchPageAccumulatorProvider
    extends
        $AsyncNotifierProvider<SearchPageAccumulator, GalleryAccumulatorState> {
  /// 搜索分页累积 Provider（按 keyword）。
  ///
  /// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
  /// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
  /// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
  SearchPageAccumulatorProvider._({
    required SearchPageAccumulatorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchPageAccumulatorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchPageAccumulatorHash();

  @override
  String toString() {
    return r'searchPageAccumulatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchPageAccumulator create() => SearchPageAccumulator();

  @override
  bool operator ==(Object other) {
    return other is SearchPageAccumulatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchPageAccumulatorHash() =>
    r'6693c69f24625245d055f5afb8e229fc3cfe7465';

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。

final class SearchPageAccumulatorFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchPageAccumulator,
          AsyncValue<GalleryAccumulatorState>,
          GalleryAccumulatorState,
          FutureOr<GalleryAccumulatorState>,
          String
        > {
  SearchPageAccumulatorFamily._()
    : super(
        retry: null,
        name: r'searchPageAccumulatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 搜索分页累积 Provider（按 keyword）。
  ///
  /// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
  /// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
  /// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。

  SearchPageAccumulatorProvider call(String keyword) =>
      SearchPageAccumulatorProvider._(argument: keyword, from: this);

  @override
  String toString() => r'searchPageAccumulatorProvider';
}

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。

abstract class _$SearchPageAccumulator
    extends $AsyncNotifier<GalleryAccumulatorState> {
  late final _$args = ref.$arg as String;
  String get keyword => _$args;

  FutureOr<GalleryAccumulatorState> build(String keyword);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<GalleryAccumulatorState>,
              GalleryAccumulatorState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<GalleryAccumulatorState>,
                GalleryAccumulatorState
              >,
              AsyncValue<GalleryAccumulatorState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

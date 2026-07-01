import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/domain/entities/gallery_accumulator_state.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/repository_providers.dart';

part 'search_page_accumulator_provider.g.dart';

/// 搜索 Provider — 调用 JS [client.search] 获取一页搜索结果。
///
/// 返回值格式与 [galleryProvider] 一致（[GalleryPageData]），
/// 由 [SearchPageAccumulator] 调用以累积分页数据。
@riverpod
Future<GalleryPageData> search(
  Ref ref, {
  required String keyword,
  required int page,
}) async {
  final repo = ref.watch(jsGalleryRepositoryProvider);

  final result = await repo.search(keyword: keyword, page: page);

  return result.when(success: (data) => data, failure: (error) => throw error);
}

/// 搜索分页累积 Provider（按 keyword）。
///
/// 封装搜索的分页累积逻辑，复用 [GalleryAccumulatorState]（因为
/// [client.search] 返回格式与 [client.fetchGallery] 完全相同）。
/// 当 keyword 变化时 Riverpod 自动重建，状态自然清零。
@riverpod
class SearchPageAccumulator extends _$SearchPageAccumulator {
  @override
  Future<GalleryAccumulatorState> build(String keyword) async {
    ref.onDispose(() {
      iLogger.d('SearchPageAccumulator: disposed keyword="$keyword"');
    });
    return GalleryAccumulatorState.empty();
  }

  /// 加载下一页搜索结果。
  ///
  /// 首次调用相当于加载第 1 页。如果已在加载中或没有更多页，
  /// 直接返回不执行。
  Future<void> loadNext() async {
    final current = state.requireValue;
    if (current.isLoading || !current.hasMore) return;

    final nextPage = current.currentPage + 1;
    state = AsyncValue.data(current.copyWith(isLoading: true, error: null));

    try {
      final pageData = await ref.read(
        searchProvider(keyword: keyword, page: nextPage).future,
      );
      state = AsyncValue.data(
        GalleryAccumulatorState(
          items: [...current.items, ...pageData.list],
          currentPage: nextPage,
          totalPage: pageData.totalPage,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e) {
      iLogger.e('SearchPageAccumulator: loadNext error: $e');
      state = AsyncValue.data(current.copyWith(isLoading: false, error: e));
    }
  }

  /// 刷新：重置为空状态后重新搜索。
  Future<void> refresh() async {
    state = AsyncValue.data(GalleryAccumulatorState.empty());
    await loadNext();
  }
}

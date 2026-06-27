import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/data/datasources/remote/detail_worker_pool.dart';
import 'package:rohos_app/domain/entities/detail_accumulator_state.dart';
import 'package:rohos_app/domain/entities/detail_item.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart';

part 'detail_page_accumulator_provider.g.dart';

/// 全局共享的 [DetailWorkerPool] 实例。
final detailWorkerPoolProvider = Provider<DetailWorkerPool>((ref) {
  final pool = DetailWorkerPool();
  ref.onDispose(() => pool.dispose());
  return pool;
});

/// 详情分页累积 Provider（按 URL）。
@riverpod
class DetailPageAccumulator extends _$DetailPageAccumulator {
  JsConfigData? _cachedConfig;

  @override
  Future<DetailAccumulatorState> build(String url) async {
    final config = await ref.watch(jsConfigProvider.future);
    _cachedConfig = config;
    await ref.read(detailWorkerPoolProvider).init();
    return DetailAccumulatorState.empty();
  }

  /// 加载下一页。
  Future<void> loadNext() async {
    final current = state.requireValue;
    if (current.isLoading || !current.hasMore) return;

    final nextUrl = current.nextPageUrl ??
        (current.lastLoadedUrl != null
            ? _buildNextPageUrl(current.lastLoadedUrl!, current.currentPage + 1)
            : url);

    await _loadPage(
      targetUrl: nextUrl,
      targetPage: current.currentPage + 1,
      previousItems: current.items,
      fallbackTotalPage: current.totalPage,
    );
  }

  /// 刷新：重新加载首页。
  Future<void> refresh() async {
    await _loadPage(
      targetUrl: url,
      targetPage: 1,
      previousItems: const [],
      fallbackTotalPage: null,
    );
  }

  /// 加载单页并更新 state — loadNext / refresh 共用。
  Future<void> _loadPage({
    required String targetUrl,
    required int targetPage,
    required List<DetailItem> previousItems,
    int? fallbackTotalPage,
  }) async {
    // 设置 loading 状态
    final before = state.valueOrNull;
    state = AsyncValue.data(
      (before ?? DetailAccumulatorState.empty())
          .copyWith(isLoading: true, clearError: true),
    );

    try {
      final detail = await _loadViaPool(url: targetUrl, current: targetPage);

      state = AsyncValue.data(
        DetailAccumulatorState(
          items: [...previousItems, ...detail.list],
          currentPage: targetPage,
          totalPage: detail.totalPage ?? fallbackTotalPage ?? 1,
          nextPageUrl: detail.nextPageUrl,
          lastLoadedUrl: targetUrl,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e) {
      final after = state.valueOrNull;
      if (after != null) {
        state = AsyncValue.data(after.copyWith(isLoading: false, error: e));
      }
    }
  }

  Future<GalleryDetail> _loadViaPool({
    required String url,
    required int current,
  }) async {
    final config = _cachedConfig!;
    final pool = ref.read(detailWorkerPoolProvider);
    return pool.execute(
      url: url,
      jsSource: config.jsContent,
      name: config.name,
      current: current,
    );
  }
}

String _buildNextPageUrl(String baseUrl, int nextPage) {
  final uri = Uri.parse(baseUrl);
  final newQuery = Map<String, String>.from(uri.queryParameters);
  newQuery['page'] = nextPage.toString();
  return uri.replace(queryParameters: newQuery).toString();
}

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/data/datasources/remote/detail_worker_pool.dart';
import 'package:rohos_app/domain/entities/detail_accumulator_state.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart';

part 'detail_page_accumulator_provider.g.dart';

/// 全局共享的 [DetailWorkerPool] 实例。
///
/// 每个 Isolate 内 [JsRuntimeLib] 只初始化一次，后续任务复用。
final detailWorkerPoolProvider = Provider<DetailWorkerPool>((ref) {
  final pool = DetailWorkerPool();
  ref.onDispose(() => pool.dispose());
  return pool;
});

/// 详情分页累积 Provider（按 URL）。
///
/// [build] 只获取 JS 配置和初始化 Worker 池，不加载数据。
/// 首页数据由 [InfiniteScrollView] 的 [autoLoad] 触发 [refresh()] 来加载。
/// [loadNext] 加载后续分页，[refresh] 重新加载首页。
@riverpod
class DetailPageAccumulator extends _$DetailPageAccumulator {
  // 缓存 JS 配置，避免每次 load 都重新 watch
  JsConfigData? _cachedConfig;

  @override
  Future<DetailAccumulatorState> build(String url) async {
    final config = await ref.watch(jsConfigProvider.future);
    _cachedConfig = config;

    // 确保 Worker 池已初始化
    final pool = ref.watch(detailWorkerPoolProvider);
    try {
      await pool.init();
    } catch (_) {
      // init 已在首次调用时完成，后续调用忽略
    }

    return DetailAccumulatorState.empty();
  }

  /// 加载下一页。
  Future<void> loadNext() async {
    final current = state.requireValue;
    if (current.isLoading || !current.hasMore) return;

    state = AsyncValue.data(
      current.copyWith(isLoading: true, clearError: true),
    );

    try {
      final nextUrl = current.nextPageUrl ??
          (current.lastLoadedUrl != null
              ? _buildNextPageUrl(
                  current.lastLoadedUrl!, current.currentPage + 1)
              : url);

      final detail = await _loadViaPool(
        url: nextUrl,
        current: current.currentPage + 1,
      );

      state = AsyncValue.data(
        DetailAccumulatorState(
          items: [...current.items, ...detail.list],
          currentPage: current.currentPage + 1,
          totalPage: detail.totalPage ?? current.totalPage,
          nextPageUrl: detail.nextPageUrl,
          lastLoadedUrl: nextUrl,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false, error: e));
    }
  }

  /// 刷新：重新加载首页。
  Future<void> refresh() async {
    try {
      final detail = await _loadViaPool(url: url, current: 1);
      state = AsyncValue.data(
        DetailAccumulatorState(
          items: detail.list,
          currentPage: 1,
          totalPage: detail.totalPage,
          nextPageUrl: detail.nextPageUrl,
          lastLoadedUrl: url,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e, st) {
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(error: e));
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 通过 Worker 池加载单页详情。
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

/// 从当前 URL 构造带 page 参数的下一页 URL。
String _buildNextPageUrl(String baseUrl, int nextPage) {
  final uri = Uri.parse(baseUrl);
  final newQuery = Map<String, String>.from(uri.queryParameters);
  newQuery['page'] = nextPage.toString();
  return uri.replace(queryParameters: newQuery).toString();
}

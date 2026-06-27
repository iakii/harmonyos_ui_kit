import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/data/datasources/remote/detail_worker.dart';
import 'package:rohos_app/domain/entities/detail_accumulator_state.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart';

part 'detail_page_accumulator_provider.g.dart';

// ─── Provider ───────────────────────────────────────────────────

/// 详情分页累积 Provider（按 URL）。
///
/// [build] 只获取 JS 配置，不加载数据。首页数据由 [InfiniteScrollView] 的
/// [autoLoad] 触发 [refresh()] 来加载。UI 通过 [AsyncValue.when] 展示状态。
/// [loadNext] 加载后续分页，[refresh] 重新加载首页。
@riverpod
class DetailPageAccumulator extends _$DetailPageAccumulator {
  @override
  Future<DetailAccumulatorState> build(String url) async {
    ref.onDispose(() {
      // isolate 会在 _loadSinglePage 的 finally 块中清理
    });
    // 仅获取 JS 配置（确保可用），不加载第一页数据
    // 第一页数据由 InfiniteScrollView 的 autoLoad 触发 refresh() 加载
    await ref.watch(jsConfigProvider.future);
    return DetailAccumulatorState.empty();
  }

  /// 加载下一页。
  ///
  /// 如果已在加载中或没有更多页（[DetailAccumulatorState.hasMore]），
  /// 直接返回不执行。加载完成后通过 [state] 更新 UI。
  Future<void> loadNext() async {
    final current = state.requireValue;
    if (current.isLoading || !current.hasMore) return;

    state = AsyncValue.data(
      current.copyWith(isLoading: true, clearError: true),
    );

    try {
      // 确定下一页 URL：优先 nextPageUrl，否则从 lastLoadedUrl 构造
      final nextUrl =
          current.nextPageUrl ??
          _buildNextPageUrl(current.lastLoadedUrl!, current.currentPage + 1);

      // 获取 JS 配置并加载单页
      final config = await ref.watch(jsConfigProvider.future);
      final detail = await _loadSinglePage(
        url: nextUrl,
        jsSource: config.jsContent,
        name: config.name,
        current: current.currentPage + 1,
      );

      state = AsyncValue.data(
        DetailAccumulatorState(
          items: [...current.items, ...detail.list],
          currentPage: current.currentPage + 1,
          // 新响应中的 totalPage 可能更新，否则沿用旧值
          totalPage: detail.totalPage ?? current.totalPage,
          // nextPageUrl 以最新响应为准
          nextPageUrl: detail.nextPageUrl,
          lastLoadedUrl: nextUrl,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(current.copyWith(isLoading: false, error: e));
      // 不 rethrow，让 UI 通过 state.error 感知
    }
  }

  /// 刷新：重新加载首页。
  ///
  /// 不重置 state 为 loading（由 SmartRefresher 管理刷新指示器），
  /// 加载完成后替换数据。
  Future<void> refresh() async {
    try {
      final config = await ref.watch(jsConfigProvider.future);
      final detail = await _loadSinglePage(
        url: url,
        jsSource: config.jsContent,
        name: config.name,
        current: 1,
      );
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
      // 刷新失败：保留旧数据，记录错误
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncValue.data(current.copyWith(error: e));
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

/// 从当前 URL 构造带 page 参数的下一页 URL。
String _buildNextPageUrl(String baseUrl, int nextPage) {
  final uri = Uri.parse(baseUrl);
  final newQuery = Map<String, String>.from(uri.queryParameters);
  newQuery['page'] = nextPage.toString();
  return uri.replace(queryParameters: newQuery).toString();
}

// ─── 单页加载（后台 isolate） ───────────────────────────────────

/// 在后台 Isolate 中执行一次 fetchDetails(url)，等待最终结果返回。
Future<GalleryDetail> _loadSinglePage({
  required String url,
  required String jsSource,
  required String name,
  required int current,
}) async {
  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(
    runDetailWorker,
    DetailWorkerInit(
      jsSource: jsSource,
      url: url,
      name: name,
      current: current,
      sendPort: receivePort.sendPort,
    ),
    debugName: 'DetailPageWorker',
  );

  try {
    await for (final message in receivePort) {
      final msg = message as Map<String, Object?>;
      switch (msg['type'] as String) {
        case DetailWorkerMsg.final_:
          final jsonStr = msg['data'] as String;
          if (jsonStr.isEmpty || jsonStr == 'undefined') {
            throw Exception('获取详情失败: 返回数据为空');
          }
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          return GalleryDetail.fromJson(parsed);
        case DetailWorkerMsg.error:
          throw Exception(msg['error'] as String);
      }
      // 忽略 progress 消息（单次加载不需要逐批推送）
    }
    throw Exception('意外的 isolate 流结束');
  } finally {
    try {
      isolate.kill(priority: Isolate.immediate);
    } catch (_) {}
    receivePort.close();
  }
}

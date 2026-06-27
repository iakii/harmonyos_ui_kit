import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/presentation/providers/js_gallery/repository_providers.dart';

part 'rust_daily_provider.g.dart';

/// Rust Daily 数据 Provider。
///
/// 根据 [RustDailyParams] 获取并解析 HTML，通过 [rustDailyRepositoryProvider]
/// 经由 Repository 完成 HTTP 请求和 HTML 解析。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
@riverpod
class RustDaily extends _$RustDaily {
  // ── 内部分页状态（单次 fetch 内维持） ──
  int _currentPage = 1;
  int _totalPage = 1;
  final List<String> _accumulatedItems = [];

  @override
  RustDailyPageData build(RustDailyParams params) {
    return RustDailyPageData.empty();
  }

  /// 单次加载（详情页使用）：不重置分页状态，直接获取当前 URL 内容。
  Future<void> fetch() async {
    await _fetch();
  }

  /// 下拉刷新：重置到第 1 页并重新加载。
  Future<void> refresh() async {
    _currentPage = 1;
    _totalPage = 1;
    _accumulatedItems.clear();
    await _fetch();
  }

  /// 上拉加载更多：翻页并获取下一页数据，自动追加到累积列表。
  Future<void> loadMore() async {
    if (_currentPage >= _totalPage) return;
    _currentPage++;
    await _fetch();
  }

  /// 获取当前页数据（内部方法），通过 Repository 完成 HTTP + HTML 解析。
  Future<void> _fetch() async {
    state = state.copyWith(loading: true);
    final repo = ref.read(rustDailyRepositoryProvider);

    if (params.type == "list") {
      final result = await repo.getList(
        url: params.url,
        page: _currentPage,
        tabKey: params.tabKey,
      );

      result.when(
        success: (pageData) {
          _totalPage = pageData.totalPage;

          // 第 1 页替换，后续页追加
          if (_currentPage == 1) {
            _accumulatedItems
              ..clear()
              ..addAll(pageData.liItems);
          } else {
            _accumulatedItems.addAll(pageData.liItems);
          }

          iLogger.i(
            'Rust Daily 列表模式：共 ${pageData.liItems.length} 条 <li>，总页数 $_totalPage',
          );

          final html =
              '<div style="padding:16px">\n${_accumulatedItems.join('\n')}\n</div>';

          state = state.copyWith(
            loading: false,
            html: html,
            liItems: List.of(_accumulatedItems),
            totalPage: _totalPage,
            currentPage: _currentPage,
          );
        },
        failure: (error) {
          state = state.copyWith(loading: false);
          throw error;
        },
      );
    } else {
      // ── 详情模式 ──
      final result = await repo.getDetail(url: params.url);

      result.when(
        success: (pageData) {
          state = state.copyWith(
            loading: false,
            html: pageData.html,
            liItems: [],
            totalPage: 1,
            currentPage: 1,
          );
        },
        failure: (error) {
          state = state.copyWith(loading: false);
          throw error;
        },
      );
    }
  }
}

/// Provider 参数（不含 page，一个 (url+type+tabKey) 对应一个 provider 实例）。
class RustDailyParams {
  final String url;
  final String type; // "list" | "detail"

  /// Tab 标识，用于区分不同 tab 的 provider 实例缓存。
  ///
  /// 即使两个 tab 使用了相同 URL，只要 [tabKey] 不同，
  /// [RustDailyParams] 就会被视为不同的 provider key。
  final String tabKey;

  const RustDailyParams({
    required this.url,
    required this.type,
    this.tabKey = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RustDailyParams &&
          url == other.url &&
          type == other.type &&
          tabKey == other.tabKey;

  @override
  int get hashCode => Object.hash(url, type, tabKey);
}

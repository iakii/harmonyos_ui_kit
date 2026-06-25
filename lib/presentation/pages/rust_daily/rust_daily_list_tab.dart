import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/domain/entities/rust_daily_tab.dart';
import 'package:rohos_app/presentation/providers/rust_daily/rust_daily_provider.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/presentation/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';
import 'package:rohos_app/presentation/widgets/back_to_top_button.dart';

/// 单个 Tab 的列表页。
///
/// 每个 [RustDailyListTab] 绑定一个 [tab]，独立管理自己的
/// 分页、数据缓存、滚动位置、刷新状态。
/// 通过 [AutomaticKeepAliveClientMixin] 在 [PageView] 中保持存活，
/// 切回时滚动位置和数据不变。
class RustDailyListTab extends ConsumerStatefulWidget {
  const RustDailyListTab({super.key, required this.tab});

  /// 绑定的 Tab 数据（label / url / key / icon）。
  final RustDailyTab tab;

  @override
  ConsumerState<RustDailyListTab> createState() => _RustDailyListTabState();
}

class _RustDailyListTabState extends ConsumerState<RustDailyListTab>
    with AutomaticKeepAliveClientMixin {
  // ── 分页状态 ──
  int _currentPage = 1;
  List<String> _accumulatedItems = [];
  RustDailyPageData? _cachedData;

  /// 最近一次错误，用于在 [InfiniteScrollView] 中显示错误页。
  Object? _lastError;

  // ── 加载状态 ──
  /// 是否正在加载更多（上拉分页）。
  ///
  /// 供 [InfiniteScrollView.isLoadingMore] 驱动上拉加载完的动画结束回调。
  bool _isLoadingMore = false;

  // ── 控制器 ──
  late final RefreshController _refreshController = RefreshController();
  late final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  bool get wantKeepAlive => true;

  // ═══════════════════════════════════════
  // 生命周期
  // ═══════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RustDailyListTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // tab 切换时重置（仅当绑定的 tab 变化时）
    if (oldWidget.tab.key != widget.tab.key) {
      _resetState();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final visible = _scrollController.position.pixels > 500;
    if (visible != _showBackToTop) {
      setState(() => _showBackToTop = visible);
    }
  }

  void _resetState() {
    _currentPage = 1;
    _accumulatedItems = [];
    _cachedData = null;
    _lastError = null;
    _refreshController.resetNoData();
  }

  // ═══════════════════════════════════════
  // Build
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // AutomaticKeepAliveClientMixin 要求调用 super.build
    super.build(context);

    final tab = widget.tab;
    final params = RustDailyParams(
      url: tab.url,
      type: 'list',
      page: _currentPage,
      tabKey: tab.key,
    );

    // ── Listener ──
    // 通过 ref.listen 订阅 provider 状态变化，驱动数据累积和 UI 更新。
    // 不再使用 ref.watch 隐式触发加载——初始加载交由 RefreshController 的
    // requestRefresh() 触发，加载动画由下拉刷新指示器控制，无需额外加载态。
    ref.listen(rustDailyProvider(params), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) {
        if (next.hasError) {
          _lastError = next.error;
          // 加载更多出错时重置加载态，让 InfiniteScrollView 结束上拉动效
          if (_currentPage > 1) _isLoadingMore = false;
          if (mounted) setState(() {});
        }
        return;
      }

      _lastError = null;
      _cachedData = data;

      if (data.currentPage == 1) {
        // 第 1 页：直接替换（刷新或首次加载）
        _accumulatedItems = data.liItems;
      } else {
        // 后续页：追加到已有列表
        _accumulatedItems = [..._accumulatedItems, ...data.liItems];
        _isLoadingMore = false; // 加载完成，InfiniteScrollView 检测到过渡后结束上拉动效
      }

      if (mounted) setState(() {});
    });

    // ── 展示数据 ──
    final displayHtml = _accumulatedItems.isNotEmpty
        ? '<div style="padding:16px">${_accumulatedItems.join('\n')}</div>'
        : '';
    final displayHasMore = _cachedData?.hasMore ?? false;

    // 无 ref.watch 后，错误状态通过 ref.listen 记录到 _lastError。
    // 仅在数据为空时才展示错误页（已有数据时不覆盖）。
    final hasError = _lastError != null && displayHtml.isEmpty;

    // ── 下拉刷新 ──
    // 初始加载和手动下拉刷新都经过此路径。初始时由 initState 中的
    // _refreshController.requestRefresh() 触发，自带下拉动画。
    Future<void> onRefresh() async {
      console.d("onRefresh: url=${tab.url}, tabKey=${tab.key}");
      // 重置到第 1 页，清空累积数据
      _currentPage = 1;
      _accumulatedItems = [];
      _cachedData = null;
      _lastError = null;
      _refreshController.resetNoData();
      // 失效 provider 后重新读取，利用 Riverpod 缓存避免重复请求
      final p = rustDailyProvider(
        RustDailyParams(url: tab.url, type: 'list', page: 1, tabKey: tab.key),
      );
      ref.invalidate(p);
      await ref.read(p.future);
      // InfiniteScrollView._onRefresh 等待此 Future 完成后自动调 refreshCompleted()
    }

    // ── 加载更多 ──
    // 上拉触发的分页加载。翻页后通过 ref.invalidate 显式触发新 provider 实例，
    // 而非依赖 ref.watch 隐式响应——因为本页面使用 ref.listen 替代 ref.watch。
    void onLoadMore() {
      if (!displayHasMore) return;
      setState(() {
        _currentPage++;
        _isLoadingMore = true; // InfiniteScrollView 据此展示上拉加载态
      });
      // 用新页码构造 provider key，失效后触发该实例的 build
      final p = rustDailyProvider(
        RustDailyParams(
          url: widget.tab.url,
          type: 'list',
          page: _currentPage,
          tabKey: widget.tab.key,
        ),
      );
      ref.invalidate(p);
    }

    return Stack(
      children: [
        InfiniteScrollView(
          controller: _scrollController,
          refreshController: _refreshController,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          hasMore: displayHasMore,
          isLoadingMore: _isLoadingMore,
          children: [
            SizedBox(height: 28), // 顶部留空给 HosTabBar
            if (hasError)
              HosErrorState(
                message: _lastError.toString(),
                onRetry: () => ref.invalidate(rustDailyProvider(params)),
              ),
            if (displayHtml.isNotEmpty)
              HtmlWidget(
                displayHtml,
                textStyle: const TextStyle(fontSize: 15),
                onTapUrl: (url) {
                  router.push(
                    '/rust',
                    extra: {'url': url, 'type': 'detail', 'title': tab.label},
                  );
                  return true;
                },
                onLoadingBuilder: (context, element, loadingProgress) =>
                    const Loading(size: 64),
                customWidgetBuilder: customWidgetBuilder,
              ),
          ],
        ),

        // ── 返回顶部 ──
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 24,
            child: BackToTopButton(scrollController: _scrollController),
          ),
      ],
    );
  }
}


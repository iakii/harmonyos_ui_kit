import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/domain/entities/rust_daily_tab.dart';
import 'package:rohos_app/presentation/providers/rust_daily/rust_daily_provider.dart';
import 'package:rohos_app/presentation/widgets/back_to_top_button.dart';
import 'package:rohos_app/presentation/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';
import 'package:rohos_app/router_args.dart';
import 'package:rohos_app/router.dart' show router;

/// 单个 Tab 的列表页。
///
/// 每个 [RustDailyListTab] 绑定一个 [tab]，独立管理自己的
/// 分页、数据缓存、滚动位置、刷新状态。
/// 通过 [AutomaticKeepAliveClientMixin] 在 [PageView] 中保持存活，
/// 切回时滚动位置和数据不变。
///
/// 分页状态（_currentPage / _accumulatedItems）由 [RustDaily] provider
/// 内部维护，widget 只需调用 refresh() / loadMore() 方法。
class RustDailyListTab extends ConsumerStatefulWidget {
  const RustDailyListTab({super.key, required this.tab});

  /// 绑定的 Tab 数据（label / url / key / icon）。
  final RustDailyTab tab;

  @override
  ConsumerState<RustDailyListTab> createState() => _RustDailyListTabState();
}

class _RustDailyListTabState extends ConsumerState<RustDailyListTab>
    with AutomaticKeepAliveClientMixin {
  // ── 加载状态 ──
  /// 是否正在加载更多（上拉分页）。
  ///
  /// 供 [InfiniteScrollView.isLoadingMore] 驱动上拉加载完的动画结束回调。
  bool _isLoadingMore = false;

  /// 最近一次错误，用于在 [InfiniteScrollView] 中显示错误页。
  Object? _lastError;

  // ── 控制器 ──
  late final RefreshController _refreshController = RefreshController();
  late final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  /// 当前 tab 绑定的 provider 参数（不含 page，贯穿所有分页）。
  late final RustDailyParams _params = RustDailyParams(
    url: widget.tab.url,
    type: 'list',
    tabKey: widget.tab.key,
  );

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

    final displayHtml = ref.watch(
      rustDailyProvider(_params).select((value) => value.html),
    );
    final hasMore = ref.watch(
      rustDailyProvider(_params).select((value) => value.hasMore),
    );

    // 仅在数据为空时才展示错误页（已有数据时不覆盖）。
    final hasError = _lastError != null && displayHtml.isEmpty;

    // ── 下拉刷新 ──
    // 初始加载和手动下拉刷新都经过此路径。初始时由 InfiniteScrollView 的
    // autoRequestRefresh 触发自带下拉动画。
    Future<void> onRefresh() async {
      _lastError = null;
      try {
        await ref.read(rustDailyProvider(_params).notifier).refresh();
      } catch (e) {
        _lastError = e;
        if (mounted) setState(() {});
        rethrow; // InfiniteScrollView 据此调 refreshFailed()
      }
    }

    // ── 加载更多（供 InfiniteScrollView children 模式 fire-and-forget 调用） ──
    Future<void> onLoadMore() async {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
      await ref
          .read(rustDailyProvider(_params).notifier)
          .loadMore()
          .then((_) {
            // loadMore 完成后（含快速返回的无更多页情况），重置加载态
            if (mounted) setState(() => _isLoadingMore = false);
          })
          .catchError((Object e) {
            iLogger.e('加载更多失败: $e');
            if (mounted) {
              setState(() {
                _isLoadingMore = false;
                _lastError = e;
              });
            }
          });
    }

    return Stack(
      children: [
        InfiniteScrollView.children(
          controller: _scrollController,
          refreshController: _refreshController,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          hasMore: hasMore,
          isLoadingMore: _isLoadingMore,
          children: [
            SizedBox(height: 28), // 顶部留空给 HosTabBar
            if (hasError)
              HosErrorState(
                message: _lastError.toString(),
                onRetry: () {
                  _lastError = null;
                  ref
                      .read(rustDailyProvider(_params).notifier)
                      .refresh()
                      .catchError((e) {
                        _lastError = e;
                        if (mounted) setState(() {});
                      });
                },
              ),
            if (displayHtml.isNotEmpty)
              HtmlWidget(
                displayHtml,
                textStyle: const TextStyle(fontSize: 15),
                onTapUrl: (url) {
                  router.push(
                    '/rust',
                    extra: RustDailyRouteArgs(
                      url: url,
                      type: 'detail',
                      title: widget.tab.label,
                    ),
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

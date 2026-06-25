import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rohos_app/models/rust_daily_data.dart';
import 'package:rohos_app/providers/rust_daily_provider.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/services/logger.dart';
import 'package:rohos_app/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/widgets/infinite_scroll_view.dart';
import 'package:rohos_app/widgets/loading.dart';

/// 单个 Tab 的列表页。
///
/// 每个 [RustDailyListTab] 绑定一个 [tab]，独立管理自己的
/// 分页、数据缓存、滚动位置、刷新状态。
/// 通过 [AutomaticKeepAliveClientMixin] 在 [PageView] 中保持存活，
/// 切回时滚动位置和数据不变。
class RustDailyListTab extends ConsumerStatefulWidget {
  const RustDailyListTab({
    super.key,
    required this.tab,
  });

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

    final asyncData = ref.watch(rustDailyProvider(params));

    // ── Listener ──
    ref.listen(rustDailyProvider(params), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) return;

      _cachedData = data;

      if (data.currentPage == 1) {
        _accumulatedItems = data.liItems;
      } else {
        _accumulatedItems = [..._accumulatedItems, ...data.liItems];
      }
    });

    final isLoading = asyncData.isLoading;

    // ── 展示数据 ──
    final displayHtml = _accumulatedItems.isNotEmpty
        ? '<div style="padding:16px">${_accumulatedItems.join('\n')}</div>'
        : '';
    final displayHasMore = _cachedData?.hasMore ?? false;

    final hasError = asyncData.hasError && displayHtml.isEmpty;
    final isLoadingMore = isLoading && _currentPage > 1;

    // ── 下拉刷新 ──
    Future<void> onRefresh() async {
      iLogger.d("onRefresh: url=${tab.url}, tabKey=${tab.key}");
      _currentPage = 1;
      _accumulatedItems = [];
      _cachedData = null;
      _refreshController.resetNoData();
      final p = rustDailyProvider(
        RustDailyParams(url: tab.url, type: 'list', page: 1, tabKey: tab.key),
      );
      ref.invalidate(p);
      await ref.read(p.future);
    }

    // ── 加载更多 ──
    void onLoadMore() {
      if (displayHasMore) {
        setState(() => _currentPage++);
      }
    }

    return Stack(
      children: [
        InfiniteScrollView(
          controller: _scrollController,
          refreshController: _refreshController,
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          hasMore: displayHasMore,
          isLoadingMore: isLoadingMore,
          children: [
            if (hasError)
              HosErrorState(
                message: asyncData.error.toString(),
                onRetry: () => ref.invalidate(rustDailyProvider(params)),
              ),
            if (displayHtml.isNotEmpty)
              HtmlWidget(
                displayHtml,
                textStyle: const TextStyle(fontSize: 15),
                onTapUrl: (url) {
                  router.push(
                    '/rust',
                    extra: {
                      'url': url,
                      'type': 'detail',
                      'title': tab.label,
                    },
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
            child: _BackToTopButton(scrollController: _scrollController),
          ),
      ],
    );
  }
}

/// 返回顶部悬浮按钮。
class _BackToTopButton extends StatefulWidget {
  const _BackToTopButton({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<_BackToTopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: const Icon(HMIcons.arrowshapeUpToLine),
          onPressed: () {
            widget.scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }
}

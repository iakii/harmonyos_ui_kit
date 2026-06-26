import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/utils/logger.dart' show iLogger;
import 'package:rohos_app/domain/entities/detail_accumulator_state.dart';
import 'package:rohos_app/presentation/providers/js_gallery/detail_page_accumulator_provider.dart';
import 'package:rohos_app/presentation/widgets/back_to_top_button.dart';
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart'
    show InfiniteScrollView;
import 'detail_card.dart' show DetailCard;
import 'detail_loading_widget.dart' show DetailLoadingWidget;

/// 图集详情页（分页版）。
///
/// 通过 [DetailPageAccumulator] provider 管理分页累积数据，
/// [InfiniteScrollView.paginated] 实现下拉刷新和上拉加载更多。
/// 当响应包含 totalPage 或 nextPageUrl 时启用分页，否则为单次加载。
class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.url, this.title = '详情'});

  /// 图集详情链接（从 GoRouter state.extra 传入）。
  final String url;

  /// 图集详情标题（从 GoRouter state.extra 传入）。
  final String title;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  // ── 滚动控制 ──
  late final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final visible = _scrollController.position.pixels > 500;
    if (visible != _showBackToTop) {
      setState(() => _showBackToTop = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(detailPageAccumulatorProvider(widget.url));
    final theme = HarmonyTheme.of(context);

    void onRetry() => ref.refresh(detailPageAccumulatorProvider(widget.url));

    return HosPage(
      leading: const BackIcon(),
      title: widget.title,
      backgroundColor: HarmonyTheme.of(context).surfaceColor,
      showAppBar: true,
      body: asyncState.when(
        // 初始加载（provider build 阶段）
        loading: () => DetailLoadingWidget(theme: theme),
        // 构建失败（极少发生，通常是 Riverpod 内部错误）
        error: (err, _) =>
            HosErrorState(message: err.toString(), onRetry: onRetry),
        // 正常数据
        data: (state) => _buildBody(context, state, ref, onRetry),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DetailAccumulatorState state,
    WidgetRef ref,
    VoidCallback onRetry,
  ) {
    // 错误且无缓存数据
    if (state.error != null && state.items.isEmpty && !state.isLoading) {
      return HosErrorState(message: state.error.toString(), onRetry: onRetry);
    }

    // 已加载完成但无数据
    if (state.hasLoaded && state.items.isEmpty && !state.isLoading) {
      return const HosEmptyState(message: '暂无内容');
    }

    iLogger.d('hasmore ${state.hasMore}');
    iLogger.d(state.items.map((e) => e.cover).toList());

    // 有数据（或正在加载中）→ 无限滚动
    // provider.build 只返回空状态，由 autoLoad 触发 refresh() 加载首页
    final content = InfiniteScrollView.paginated(
      controller: _scrollController,
      autoLoad: true,
      itemCount: state.items.length,
      itemBuilder: (context, index) => DetailCard(
        item: state.items[index],
        index: index,
        total: state.items.length,
      ),
      onRefresh: () => ref
          .read(detailPageAccumulatorProvider(widget.url).notifier)
          .refresh(),
      onLoadMore: () => ref
          .read(detailPageAccumulatorProvider(widget.url).notifier)
          .loadNext(),
      hasMore: state.hasMore,
      error: state.error != null && state.items.isNotEmpty ? state.error : null,
      headerItems: [
        // 加载下一页出错且有缓存数据 → 显示重试按钮
        if (state.error != null && state.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: HosErrorState(
              message: state.error.toString(),
              onRetry: () => ref
                  .read(detailPageAccumulatorProvider(widget.url).notifier)
                  .loadNext(),
            ),
          ),
      ],
      footerItems: const [SizedBox(height: 80)],
    );

    return Stack(
      children: [
        content,
        // ── 回到顶部 ──
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

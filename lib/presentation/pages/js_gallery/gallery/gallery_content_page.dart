import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/presentation/providers/js_gallery/gallery_page_accumulator_provider.dart';
import 'package:rohos_app/presentation/widgets/back_to_top_button.dart';
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart'
    show InfiniteScrollView;
import 'package:rohos_app/presentation/widgets/staggered_grid_view/staggered_grid_view.dart';
import 'grid_item_card.dart' show GridItemCard;

/// 图集内容区 — 无限滚动分页版。
///
/// 使用 [InfiniteScrollView.paginated] 实现下拉刷新和上拉加载更多，
/// 配合 [GalleryPageAccumulator] provider 管理分页累积数据。
/// URL 变化时 provider 自动重置状态。
class GalleryContentPage extends ConsumerStatefulWidget {
  const GalleryContentPage({
    super.key,
    required this.url,
    this.showAppBar = false,
    this.title = '图集',
  });

  /// 请求图集的目标 URL。
  final String url;
  final bool showAppBar;
  final String title;

  @override
  ConsumerState<GalleryContentPage> createState() =>
      _GalleryContentPageState();
}

class _GalleryContentPageState extends ConsumerState<GalleryContentPage> {
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
    // ── 从 provider 获取累积状态 ──
    // url 变化时 Riverpod 自动创建新实例，状态自然归零
    final acc = ref.watch(galleryPageAccumulatorProvider(widget.url));
    final state = acc.valueOrNull;
    final items = state?.items ?? [];
    final hasMore = state?.hasMore ?? false;
    final hasError = state?.error != null && items.isEmpty;

    // ── 计算网格列数（约 256px 一列） ──
    final crossAxisCount = (MediaQuery.sizeOf(context).width / 256)
        .floor()
        .clamp(2, 6);

    final content = InfiniteScrollView.paginated(
      controller: _scrollController,
      itemCount: items.length,
      itemBuilder: (context, index) => GridItemCard(item: items[index]),
      onRefresh: () =>
          ref.read(galleryPageAccumulatorProvider(widget.url).notifier).refresh(),
      onLoadMore: () =>
          ref.read(galleryPageAccumulatorProvider(widget.url).notifier).loadNext(),
      hasMore: hasMore,
      error: hasError ? state!.error : null,
      headerItems: [
        // 菜单栏占位（仅嵌入模式）
        if (!widget.showAppBar) const SizedBox(height: 56),
        // 错误页（无缓存数据时全屏显示）
        if (hasError)
          HosErrorState(
            message: state!.error.toString(),
            onRetry: () => ref
                .read(galleryPageAccumulatorProvider(widget.url).notifier)
                .refresh(),
          ),
        // 空列表（已加载但无数据）
        if (state?.hasLoaded == true && items.isEmpty && !hasError)
          const HosEmptyState(message: '暂无图片'),
      ],
      footerItems: const [SizedBox(height: 80)],
      contentSliverBuilder: (builder, count) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverStaggeredGrid.countBuilder(
          crossAxisCount: crossAxisCount,
          itemCount: count,
          itemBuilder: builder,
          staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
      ),
    );

    // ── 回到顶部按钮 ──
    final body = Stack(
      children: [
        content,
        if (_showBackToTop)
          Positioned(
            right: 16,
            bottom: 24,
            child: BackToTopButton(scrollController: _scrollController),
          ),
      ],
    );

    // 独立页面模式需要 HosPage 包裹
    if (widget.showAppBar) {
      return HosPage(
        showAppBar: true,
        title: widget.title,
        leading: const BackIcon(),
        body: body,
      );
    }

    return body;
  }
}

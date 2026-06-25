import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/utils/logger.dart' show console;
import 'package:rohos_app/domain/entities/detail_accumulator_state.dart';
import 'package:rohos_app/presentation/providers/js_gallery/detail_page_accumulator_provider.dart';
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart'
    show InfiniteScrollView;
import 'detail_card.dart' show DetailCard;
import 'detail_loading_widget.dart' show DetailLoadingWidget;

/// 图集详情页（分页版）。
///
/// 通过 [DetailPageAccumulator] provider 管理分页累积数据，
/// [InfiniteScrollView.paginated] 实现下拉刷新和上拉加载更多。
/// 当响应包含 totalPage 或 nextPageUrl 时启用分页，否则为单次加载。
class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.url, this.title = '详情'});

  /// 图集详情链接（从 GoRouter state.extra 传入）。
  final String url;

  /// 图集详情标题（从 GoRouter state.extra 传入）。
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(detailPageAccumulatorProvider(url));
    final theme = HarmonyTheme.of(context);

    void onRetry() => ref.refresh(detailPageAccumulatorProvider(url));

    return HosPage(
      leading: const BackIcon(),
      title: title,
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

    console.d('hasmore ${state.hasMore}');

    // 有数据（或正在加载中）→ 无限滚动
    // 首页数据已在 provider build 中加载，autoLoad=false 避免重复触发
    return InfiniteScrollView.paginated(
      autoLoad: false,
      itemCount: state.items.length,
      itemBuilder: (context, index) => DetailCard(
        item: state.items[index],
        index: index,
        total: state.items.length,
      ),
      onRefresh: () =>
          ref.read(detailPageAccumulatorProvider(url).notifier).refresh(),
      onLoadMore: () =>
          ref.read(detailPageAccumulatorProvider(url).notifier).loadNext(),
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
                  .read(detailPageAccumulatorProvider(url).notifier)
                  .loadNext(),
            ),
          ),
      ],
      footerItems: const [SizedBox(height: 80)],
    );
  }
}

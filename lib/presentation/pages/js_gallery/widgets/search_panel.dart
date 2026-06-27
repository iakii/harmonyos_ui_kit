import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/presentation/providers/js_gallery/search_page_accumulator_provider.dart';
import 'package:rohos_app/presentation/widgets/infinite_scroll_view.dart'
    show InfiniteScrollView;
import 'package:rohos_app/presentation/widgets/staggered_grid_view/staggered_grid_view.dart';
import 'package:rohos_app/presentation/pages/js_gallery/gallery/grid_item_card.dart'
    show GridItemCard;

// ═══════════════════════════════════════════════════════════════════════════════
// Providers — 搜索 UI 状态
// ═══════════════════════════════════════════════════════════════════════════════

/// 搜索输入框的 [TextEditingController]，由 Provider 管理生命周期。
final searchControllerProvider = Provider.autoDispose<TextEditingController>((
  ref,
) {
  final c = TextEditingController(text: "丝袜");
  ref.onDispose(() => c.dispose());
  return c;
});

/// 搜索框焦点节点，用于自动聚焦。
final searchFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final f = FocusNode();
  ref.onDispose(() => f.dispose());
  return f;
});

/// 输入框当前文本（随输入实时更新），用于控制搜索按钮启用状态。
final searchTextProvider = StateProvider.autoDispose<String>((ref) => '');

/// 已提交搜索的关键词（空字符串 = 未触发搜索）。
final searchKeywordProvider = StateProvider.autoDispose<String>((ref) => '');

// ═══════════════════════════════════════════════════════════════════════════════
// 入口
// ═══════════════════════════════════════════════════════════════════════════════

/// 弹出搜索面板的入口函数，以 HosBottomSheet 形式展示。
void showSearchPanel(BuildContext context) {
  showHosBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (context) {
      return const SearchPanel();
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 搜索面板
// ═══════════════════════════════════════════════════════════════════════════════

/// 搜索面板 — 输入关键词后调用 [client.search] 加载结果。
///
/// [TextEditingController] 和搜索关键词均由 Riverpod Provider 管理，
/// 组件本身为 [ConsumerWidget]，无需维护本地 State。
class SearchPanel extends ConsumerWidget {
  const SearchPanel({super.key});

  /// 提交搜索：读取输入框文本 → 更新 keyword → 触发分页加载。
  void _submitSearch(WidgetRef ref) {
    final text = ref.read(searchControllerProvider).text.trim();
    if (text.isEmpty) return;

    ref.read(searchKeywordProvider.notifier).state = text;
    ref.read(searchPageAccumulatorProvider(text).notifier).refresh();
  }

  /// 清空输入框与搜索结果（由 [HosSearchBox.onClear] 触发）。
  void _onClearSearch(WidgetRef ref) {
    ref.read(searchControllerProvider).clear();
    ref.read(searchTextProvider.notifier).state = '';
    ref.read(searchKeywordProvider.notifier).state = '';
    ref.read(searchFocusNodeProvider).requestFocus();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchControllerProvider);
    final focusNode = ref.watch(searchFocusNodeProvider);
    final currentText = ref.watch(searchTextProvider);
    final keyword = ref.watch(searchKeywordProvider);
    final hasSearch = keyword.isNotEmpty;
    final hasInput = currentText.trim().isNotEmpty;

    // 启动时自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 搜索栏 + 按钮（左右布局） ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              // HarmonyOS 搜索框（内置搜索图标 + 清除按钮 + 焦点动画）
              Expanded(
                child: HosSearchBox(
                  controller: controller,
                  focusNode: focusNode,
                  placeholder: '搜索图集…',
                  onChanged: (v) =>
                      ref.read(searchTextProvider.notifier).state = v,
                  onSubmitted: (_) => _submitSearch(ref),
                  onClear: () => _onClearSearch(ref),
                ),
              ),
              const SizedBox(width: 8),
              // 搜索按钮
              HosButton(
                onPressed: hasInput ? () => _submitSearch(ref) : null,
                child: const Text('搜索'),
              ),
            ],
          ),
        ),

        // ── 搜索结果区 ──
        if (hasSearch) ...[
          const Divider(height: 1),
          Expanded(child: _SearchResults(keyword: keyword)),
        ] else
          const Spacer(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 搜索结果
// ═══════════════════════════════════════════════════════════════════════════════

/// 搜索结果网格 — 复用 [InfiniteScrollView] + [SliverStaggeredGrid]。
///
/// 通过 [SearchPageAccumulator] 获取数据，支持下拉刷新和上拉加载更多。
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(searchPageAccumulatorProvider(keyword));
    final state = acc.valueOrNull;
    final items = state?.items ?? [];
    final hasMore = state?.hasMore ?? false;
    final hasError = state?.error != null && items.isEmpty;

    // 计算网格列数（约 256px 一列）
    final crossAxisCount = (MediaQuery.sizeOf(context).width / 256)
        .floor()
        .clamp(2, 6);

    return InfiniteScrollView.builder(
      itemCount: items.length,
      autoLoad: false,
      itemBuilder: (context, index) => GridItemCard(item: items[index]),
      onRefresh: () =>
          ref.read(searchPageAccumulatorProvider(keyword).notifier).refresh(),
      onLoadMore: () =>
          ref.read(searchPageAccumulatorProvider(keyword).notifier).loadNext(),
      hasMore: hasMore,
      error: hasError ? state!.error : null,
      headerItems: [
        // 错误提示（无缓存数据时全屏显示）
        if (hasError)
          HosErrorState(
            message: state!.error.toString(),
            onRetry: () => ref
                .read(searchPageAccumulatorProvider(keyword).notifier)
                .refresh(),
          ),
        // 空列表提示（已加载但无数据）
        if (state?.hasLoaded == true && items.isEmpty && !hasError)
          const HosEmptyState(message: '未找到相关结果'),
      ],
      footerItems: const [SizedBox(height: 80)],
      contentSliverBuilder: (builder, count) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverStaggeredGrid.countBuilder(
          addAutomaticKeepAlives: false,
          crossAxisCount: crossAxisCount,
          itemCount: count,
          itemBuilder: builder,
          staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
      ),
    );
  }
}

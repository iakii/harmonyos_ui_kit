import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/plugin/gallery_item.dart';
import '../../models/plugin/plugin_info.dart';
import '../../providers/js/gallery_provider.dart';
import '../../providers/js/plugin_info_provider.dart';
import '../../widgets/async_value_widget.dart';

/// 图集展示页。
///
/// 从 meitule.js 的 pluginInfo 获取菜单和标题，
/// 通过 getPage 加载图集列表，以 GridView 展示。
class GalleryPage extends HookConsumerWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginInfoAsync = ref.watch(pluginInfoProvider);
    final selectedTabIndex = useState(0);
    final currentPage = useState(1);

    final title = pluginInfoAsync.valueOrNull?.name ?? '图集';

    return HosPage(
      leading: const BackIcon(),
      title: title,
      body: AsyncValueWidget<PluginInfo>(
        value: pluginInfoAsync,
        error: (err, _) =>
            HosErrorState(message: err.toString(), onRetry: null),
        data: (pluginInfo) => _GalleryBody(
          pluginInfo: pluginInfo,
          selectedTabIndex: selectedTabIndex,
          currentPage: currentPage,
        ),
      ),
    );
  }
}

/// 插件信息加载完成后渲染的主体内容。
class _GalleryBody extends HookConsumerWidget {
  const _GalleryBody({
    required this.pluginInfo,
    required this.selectedTabIndex,
    required this.currentPage,
  });

  final PluginInfo pluginInfo;
  final ValueNotifier<int> selectedTabIndex;
  final ValueNotifier<int> currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menus = pluginInfo.menus;
    final website = pluginInfo.website;

    // 当前选中菜单对应的完整 URL
    final currentMenu = menus.isNotEmpty ? menus[selectedTabIndex.value] : null;
    final currentUrl = currentMenu != null
        ? '$website${currentMenu.path}'
        : website;

    // 请求图集数据
    final galleryAsync = ref.watch(
      galleryProvider((url: currentUrl, page: currentPage.value)),
    );

    // ── 缓存上一次成功数据，避免分页/切 Tab 时内容闪烁 ──
    final cachedData = useState<GalleryPageData?>(null);
    // 记录上一次的错误，避免重复弹 SnackBar
    final lastErrorKey = useRef<String?>(null);

    ref.listen(galleryProvider((url: currentUrl, page: currentPage.value)), (
      prev,
      next,
    ) {
      // 成功获取数据 → 更新缓存
      final data = next.valueOrNull;
      if (data != null) {
        cachedData.value = data;
        lastErrorKey.value = null; // 清除错误记录
        return;
      }
      // 出错且有缓存数据 → 弹 SnackBar 提示（防重复）
      if (next.hasError && cachedData.value != null) {
        final errMsg = next.error.toString();
        if (errMsg != lastErrorKey.value) {
          lastErrorKey.value = errMsg;
          _showErrorSnackBar(
            context,
            errMsg,
            () => ref.invalidate(
              galleryProvider((url: currentUrl, page: currentPage.value)),
            ),
          );
        }
      }
    });

    // 决定实际展示的数据和过渡状态
    final displayData = galleryAsync.valueOrNull ?? cachedData.value;
    final isTransitioning = galleryAsync.isLoading && cachedData.value != null;

    return Column(
      children: [
        // ── 菜单 TabBar ──
        if (menus.isNotEmpty)
          HosTabBar(
            tabs: menus.map((m) => m.label).toList(),
            selectedIndex: selectedTabIndex.value,
            onChanged: (i) {
              selectedTabIndex.value = i;
              currentPage.value = 1; // 切换 tab 时重置页码
            },
          ),
        const SizedBox(height: 8),

        // ── 图集网格 ──
        Expanded(
          child: _buildBody(
            galleryAsync: galleryAsync,
            displayData: displayData,
            isTransitioning: isTransitioning,
            currentUrl: currentUrl,
            currentPage: currentPage.value,
            ref: ref,
          ),
        ),
      ],
    );
  }

  /// 根据状态渲染不同内容。
  Widget _buildBody({
    required AsyncValue<GalleryPageData> galleryAsync,
    required GalleryPageData? displayData,
    required bool isTransitioning,
    required String currentUrl,
    required int currentPage,
    required WidgetRef ref,
  }) {
    // 首次加载（无缓存数据）→ 全屏加载动画
    if (displayData == null && galleryAsync.isLoading) {
      return const Center(child: HosLoading(message: '加载中…'));
    }

    // 出错且无缓存数据 → 全屏错误
    if (displayData == null && galleryAsync.hasError) {
      return HosErrorState(
        message: galleryAsync.error.toString(),
        onRetry: () => ref.invalidate(
          galleryProvider((url: currentUrl, page: currentPage)),
        ),
      );
    }

    // 极端情况：无数据可用
    if (displayData == null) {
      return const HosEmptyState(message: '暂无数据');
    }

    // 空列表（非加载中）
    if (displayData.list.isEmpty && !isTransitioning) {
      return const HosEmptyState(message: '暂无图片');
    }

    return _GalleryGrid(
      items: displayData.list,
      hasMore: displayData.hasMore,
      currentPage: currentPage,
      totalPage: displayData.totalPage,
      isLoading: isTransitioning,
      onPrevPage: () {
        if (currentPage > 1) {
          this.currentPage.value--;
        }
      },
      onNextPage: () {
        if (displayData.hasMore) {
          this.currentPage.value++;
        }
      },
    );
  }

  /// 显示出错 SnackBar（有缓存数据时不会全屏错误，而是轻量提示）。
  static void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    // 延迟到下一帧，避免在 build 期间操作 overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载失败: $message'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(label: '重试', onPressed: onRetry),
        ),
      );
    });
  }
}

/// GridView 网格展示 + 底部分页控件。
///
/// 分页加载时会以半透明遮罩 + 居中加载动画覆盖在旧数据上方，
/// 避免内容闪烁。
class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.items,
    required this.hasMore,
    required this.currentPage,
    required this.totalPage,
    required this.isLoading,
    required this.onPrevPage,
    required this.onNextPage,
  });

  final List<GalleryItem> items;
  final bool hasMore;
  final int currentPage;
  final int totalPage;
  final bool isLoading;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Column(
      children: [
        // ── 网格 + 加载遮罩 ──
        Expanded(
          child: Stack(
            children: [
              // 网格内容（切换分页时保持不变，不再闪烁）
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _GridItemCard(item: item);
                },
              ),

              // 加载遮罩（半透明 + 居中转圈，显示在上层）
              if (isLoading)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.06),
                      child: const Center(child: HosLoading(size: 36)),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── 分页控件 ──
        if (totalPage > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HosTextButton(
                  onPressed: currentPage > 1 && !isLoading ? onPrevPage : null,
                  child: const Text('上一页'),
                ),
                const SizedBox(width: 12),

                // 页码区（加载中显示小转圈）
                SizedBox(
                  width: 80,
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$currentPage/$totalPage',
                                overflow: TextOverflow.ellipsis,
                                style: theme.typography.caption?.copyWith(
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '$currentPage / $totalPage',
                          textAlign: TextAlign.center,
                          style: theme.typography.caption,
                        ),
                ),

                const SizedBox(width: 12),
                HosTextButton(
                  onPressed: hasMore && !isLoading ? onNextPage : null,
                  child: const Text('下一页'),
                ),
              ],
            ),
          ),
        SizedBox(height: 120),
      ],
    );
  }
}

/// 单个网格卡片：封面图 + 标题。
class _GridItemCard extends StatelessWidget {
  const _GridItemCard({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return GestureDetector(
      onTap: () => context.push('/js_gallery_detail', extra: item.link),
      child: HosCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面图（自带 HosLoading 加载动画）
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  'https://cdn.pixabay.com/photo/2016/05/31/11/26/baby-1426651_1280.jpg', // '${item.cover}8888?x-oss-process=image/resize,w_400',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.surfaceColor,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: theme.surfaceColor,
                      child: const Center(child: HosLoading()),
                    );
                  },
                ),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

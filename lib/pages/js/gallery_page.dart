import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/pages/js/setting_panel.dart' show SettingPanel;
import 'package:rohos_app/providers/js/config_provider.dart'
    show jsConfigProvider;
import 'package:rohos_app/router.dart';
import 'package:rohos_app/widgets/loading.dart' show Loading, imageLoadState;

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

  void showSetting(BuildContext context) {
    showHosBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SettingPanel();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(
      jsConfigProvider.select((selector) => selector.value?.name),
    ); //.valueOrNull?.name;

    if (assets == null || assets == '') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HosAppBar(
          leading: Icon(HMIcons.harmonyos),
          actions: [
            IconButton(
              icon: const Icon(HMIcons.squareGrid2x2CheckmarkTopleftFilled),
              onPressed: () => showSetting(context),
            ),
          ],
          title: '未配置资源',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(HMIcons.artGallery, size: 64),
              const SizedBox(height: 16),
              const Text('请先配置 JS 源文件'),
              const SizedBox(height: 8),
              HosTextButton(
                onPressed: () => showSetting(context),
                child: const Text(
                  '去设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "HarmonyOs Sans SC",
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pluginInfoAsync = ref.watch(pluginInfoProvider);
    final selectedTabIndex = useState(0);

    return AsyncValueWidget<PluginInfo>(
      value: pluginInfoAsync,
      error: (err, _) => HosPage(
        showAppBar: true,
        title: '图集',
        leading: Icon(HMIcons.harmonyos),
        body: HosErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(pluginInfoProvider),
        ),
      ),
      loading: HosPage(
        showAppBar: true,
        title: '图集',
        leading: Icon(HMIcons.harmonyos),
        body: const Center(child: Loading(size: 64)),
      ),
      data: (pluginInfo) => _GalleryBody(
        pluginInfo: pluginInfo,
        selectedTabIndex: selectedTabIndex,
      ),
    );
  }
}

/// 插件信息加载完成后渲染的主体内容。
///
/// 仅负责协调菜单栏和图集内容区，两者通过 [currentUrl] 解耦：
/// - [_GalleryMenuBar] 接收 [menus]，回传选中的菜单索引
/// - [_GalleryContent] 只接收 [url]，独立管理分页/缓存/错误
class _GalleryBody extends HookConsumerWidget {
  const _GalleryBody({
    required this.pluginInfo,
    required this.selectedTabIndex,
  });

  final PluginInfo pluginInfo;
  final ValueNotifier<int> selectedTabIndex;

  void showSetting(BuildContext context) {
    showHosBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SettingPanel();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menus = pluginInfo.menus;
    final website = pluginInfo.website;
    // 当前选中菜单对应的完整 URL
    final currentMenu = menus.isNotEmpty ? menus[selectedTabIndex.value] : null;
    final currentUrl = currentMenu != null
        ? '$website${currentMenu.path}'
        : website;

    final theme = HarmonyTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HosAppBar(
        leading: Icon(HMIcons.harmonyos),
        actions: [
          IconButton(
            icon: Loading(
              size: 36,
              color: theme.isLight ? Colors.black : Colors.white,
            ),
            onPressed: () => router.push('/loading'),
          ),

          IconButton(
            icon: const Icon(HMIcons.houseFill),
            onPressed: () => router.go('/'),
          ),

          IconButton(
            icon: const Icon(HMIcons.squareGrid2x2CheckmarkTopleftFilled),
            onPressed: () => showSetting(context),
          ),
        ],
        title: pluginInfo.name,
      ),
      body: Stack(
        children: [
          GalleryContentPage(url: currentUrl),

          _GalleryMenuBar(
            menus: menus,
            selectedIndex: selectedTabIndex.value,
            onChanged: (i) {
              selectedTabIndex.value = i;
            },
          ),
        ],
      ),
    );
  }
}

/// 菜单 TabBar 组件。
///
/// 纯展示组件，不关心数据来源，通过 [onChanged] 回传选中索引。
class _GalleryMenuBar extends StatelessWidget {
  const _GalleryMenuBar({
    required this.menus,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<MenuItem> menus;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return HosTabBar(
      tabs: menus.map((m) => m.label).toList(),
      selectedIndex: selectedIndex,
      onChanged: onChanged,
    );
  }
}

/// 图集内容区。
///
/// 完全自包含：根据 [url] 加载图集、管理分页、缓存及错误处理。
/// 与菜单完全解耦 —— url 变化时自动重置页码。
class GalleryContentPage extends HookConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // ── 内部状态 ──
    final currentPage = useState(1);

    // url 变化时重置页码
    useEffect(() {
      currentPage.value = 1;
      return null;
    }, [url]);

    final galleryAsync = ref.watch(
      galleryProvider(url: url, page: currentPage.value),
    );

    // ── 缓存上一次成功数据，避免分页/切 Tab 时内容闪烁 ──
    final cachedData = useState<GalleryPageData?>(null);
    final lastErrorKey = useRef<String?>(null);

    ref.listen(galleryProvider(url: url, page: currentPage.value), (
      prev,
      next,
    ) {
      final data = next.valueOrNull;
      if (data != null) {
        cachedData.value = data;
        lastErrorKey.value = null;
        return;
      }
      if (next.hasError && cachedData.value != null) {
        final errMsg = next.error.toString();
        if (errMsg != lastErrorKey.value) {
          lastErrorKey.value = errMsg;
          _showGalleryErrorSnackBar(
            context,
            errMsg,
            () => ref.invalidate(
              galleryProvider(url: url, page: currentPage.value),
            ),
          );
        }
      }
    });

    final displayData = galleryAsync.valueOrNull ?? cachedData.value;
    final isTransitioning = galleryAsync.isLoading && cachedData.value != null;

    // ── 状态渲染 ──

    // 首次加载（无缓存数据）
    if (displayData == null && galleryAsync.isLoading) {
      return HosPage(
        showAppBar: showAppBar,
        title: title,
        leading: showAppBar ? const BackIcon() : null,
        body: const Center(child: Loading(size: 64)),
      );
    }

    // 出错且无缓存数据
    if (displayData == null && galleryAsync.hasError) {
      return HosPage(
        showAppBar: showAppBar,
        title: title,
        leading: showAppBar ? const BackIcon() : null,
        body: HosErrorState(
          message: galleryAsync.error.toString(),
          onRetry: () => ref.invalidate(
            galleryProvider(url: url, page: currentPage.value),
          ),
        ),
      );
    }

    // 极端情况：无数据可用
    if (displayData == null) {
      return HosPage(
        showAppBar: showAppBar,
        title: title,
        leading: showAppBar ? const BackIcon() : null,
        body: const HosEmptyState(message: '暂无数据'),
      );
    }

    // 空列表（非加载中）
    if (displayData.list.isEmpty && !isTransitioning) {
      return HosPage(
        showAppBar: showAppBar,
        title: title,
        leading: showAppBar ? const BackIcon() : null,
        body: const HosEmptyState(message: '暂无图片'),
      );
    }

    return HosPage(
      showAppBar: showAppBar,
      title: title,
      backgroundColor: showAppBar ? null : Colors.transparent,
      leading: showAppBar ? const BackIcon() : null,
      body: _GalleryGrid(
        items: displayData.list,
        hasMore: displayData.hasMore,
        currentPage: currentPage.value,
        totalPage: displayData.totalPage,
        isLoading: isTransitioning,
        onPrevPage: () {
          if (currentPage.value > 1) {
            currentPage.value--;
          }
        },
        onNextPage: () {
          if (displayData.hasMore) {
            currentPage.value++;
          }
        },
      ),
    );
  }
}

/// 显示出错 SnackBar（有缓存数据时不会全屏错误，而是轻量提示）。
void _showGalleryErrorSnackBar(
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

    return Stack(
      children: [
        // 网格内容（切换分页时保持不变，不再闪烁）
        ListView(
          children: [
            SizedBox(height: 40),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3 / 4,
                // mainAxisExtent: 100,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _GridItemCard(item: item);
              },
            ),
          ],
        ),
        // 加载遮罩（半透明 + 居中转圈，显示在上层）
        if (isLoading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withValues(alpha: 0.06),
                child: const Center(child: Loading(size: 64)),
              ),
            ),
          ),
        // ── 分页控件 ──
        if (totalPage > 1)
          Pagination(
            theme: theme,
            currentPage: currentPage,
            isLoading: isLoading,
            onPrevPage: onPrevPage,
            totalPage: totalPage,
            hasMore: hasMore,
            onNextPage: onNextPage,
          ),
      ],
    );
  }
}

class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.theme,
    required this.currentPage,
    required this.isLoading,
    required this.onPrevPage,
    required this.totalPage,
    required this.hasMore,
    required this.onNextPage,
  });

  final HarmonyThemeData theme;
  final int currentPage;
  final bool isLoading;
  final VoidCallback onPrevPage;
  final int totalPage;
  final bool hasMore;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 48,
        height: 136,
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HosTextButton(
              enabled: currentPage > 1 && !isLoading,
              onPressed: currentPage > 1 && !isLoading ? onPrevPage : null,
              child: Icon(HMIcons.chevronLeftCircle, size: 32),
            ),

            // 页码区（加载中显示小转圈）
            SizedBox(
              width: 80,
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ],
                    )
                  : null,
              // : Text(
              //     '$currentPage / $totalPage',
              //     textAlign: TextAlign.center,
              //     style: theme.typography.caption,
              //   ),
            ),

            HosTextButton(
              enabled: hasMore && !isLoading,
              onPressed: hasMore && !isLoading ? onNextPage : null,
              child: Icon(HMIcons.chevronRightCircle, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个网格卡片：封面图 + 标题。
class _GridItemCard extends ConsumerWidget {
  const _GridItemCard({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HarmonyTheme.of(context);

    final headers = ref.read(
      pluginInfoProvider.select((selector) => selector.value?.headers ?? {}),
    );
    return GestureDetector(
      onTap: () {
        if (item.link.isEmpty || item.to == 'none') return;

        context.push(
          item.to == 'gallery' ? '/js_gallery_list' : '/js_gallery_detail',
          extra: {"title": item.title, 'url': item.link},
        );
      },
      child: HosCard(
        margin: EdgeInsets.zero,
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
                child: ExtendedImage.network(
                  // 'https://cdn.pixabay.com/photo/2016/05/31/11/26/baby-1426651_1280.jpg', //
                  item.cover,
                  fit: BoxFit.cover,
                  headers: {
                    "referer": item.cover,
                    "referrerpolicy": "unsafe-url",
                    ...headers,
                  },
                  handleLoadingProgress: true,
                  // cache: false,
                  loadStateChanged: imageLoadState,
                ),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: "HarmonyOs Sans SC",
                    ),
                  ),
                  if (item.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: item.tags
                            .map(
                              (tag) => InkWell(
                                onTap: () {
                                  if (tag.to == 'none' ||
                                      tag.href == null ||
                                      tag.href == '') {
                                    return;
                                  }

                                  context.push(
                                    tag.to == 'gallery'
                                        ? "/js_gallery_list"
                                        : '/js_gallery_detail',
                                    extra: {
                                      'title': tag.title ?? '',
                                      'url': tag.href ?? '',
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag.title ?? '',
                                    style: theme.typography.overline?.copyWith(
                                      fontSize: 12,
                                      fontFamily: "HarmonyOs Sans SC",
                                      color: theme.accentColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

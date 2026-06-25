# 将分页逻辑迁移到 InfiniteScrollView 内部

## Context

当前 `InfiniteScrollView` 只是一个薄包装，所有分页/刷新状态管理仍在外部：

| 外部管理 | 在 InfiniteScrollView 内 |
|----------|------------------------|
| `RefreshController` 创建/销毁 | ❌ 外部传入 |
| `onRefresh` → `refreshCompleted`/`refreshFailed` | ❌ 外部手写 |
| `onLoadMore` → `loadComplete`/`loadNoData` | ❌ 外部手写 `isLoadingMore` |
| 错误/空数据处理 | ❌ 外部手写 |
| 首次自动加载 | ✅ `autoRequestRefresh` |

`GalleryContentPage` 和 `RustDailyListTab` 各自写了 100+ 行几乎相同的 SmartRefresher 生命周期管理代码。

**目标**：将 `RefreshController` 管理、SmartRefresher 状态转换（refreshCompleted/loadComplete 等）内化到 `InfiniteScrollView` 中，外部只提供异步回调。

## 设计方案

### `InfiniteScrollView` — 增强为自包含分页组件

变为 `ConsumerStatefulWidget`（Riverpod 集成），内部全权管理：

```dart
class InfiniteScrollView extends ConsumerStatefulWidget {
  const InfiniteScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.headerItems = const [],
    this.footerItems = const [],
    // 数据加载回调
    required this.onRefresh,    // Future<void> Function() — 刷新
    required this.onLoadMore,   // Future<void> Function() — 加载更多
    required this.hasMore,      // 是否还有更多页
    // 状态指示
    this.error,                 // 当前错误（非 null 且 items 为空时显示）
    // 可选配置
    this.autoLoad = true,
    this.scrollController,
    this.gridDelegate,          // 可选的网格布局（替代默认 ListView）
  });
}
```

内部 State：
- 持有 `RefreshController`（不再由外部传入）
- `onRefresh` 回调 → await → `refreshCompleted()` / `refreshFailed()`
- `onLoadMore` 回调 → await → `loadComplete()` / `loadNoData()` / `loadFailed()`
- 维护 `isRefreshing` / `isLoadingMore` 状态（驱动动画）
- `initState` → `requestRefresh()` 自动首次加载
- 应用生命周期观察（`WidgetsBindingObserver`）

### `GalleryContentPage` — 降级为 ConsumerWidget

当前 190 行 → 目标 ~50 行：

```dart
class GalleryContentPage extends ConsumerWidget {
  const GalleryContentPage({
    super.key,
    required this.url,
    this.showAppBar = false,
    this.title = '图集',
  });

  final String url;
  final bool showAppBar;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(galleryPageAccumulatorProvider(url));
    final state = acc.valueOrNull;
    final items = state?.items ?? [];
    final hasMore = state?.hasMore ?? false;
    final hasError = state?.error != null && items.isEmpty;

    final crossAxisCount = (MediaQuery.sizeOf(context).width / 256)
        .floor().clamp(2, 6);

    final content = InfiniteScrollView(
      itemCount: items.length,
      itemBuilder: (context, index) => GridItemCard(item: items[index]),
      onRefresh: () => ref.read(galleryPageAccumulatorProvider(url).notifier).refresh(),
      onLoadMore: () => ref.read(galleryPageAccumulatorProvider(url).notifier).loadNext(),
      hasMore: hasMore,
      error: hasError ? state?.error : null,
      headerItems: [
        if (!showAppBar) const SizedBox(height: 56),
        if (hasError)
          HosErrorState(message: state!.error.toString(), onRetry: /*...*/),
        if (!hasError && state?.hasLoaded == true && items.isEmpty)
          const HosEmptyState(message: '暂无图片'),
      ],
      gridDelegate: StaggeredGridDelegate(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
    );

    if (showAppBar) {
      return HosPage(showAppBar: true, title: title, leading: BackIcon(), body: content);
    }
    return content;
  }
}
```

不再需要 `_GalleryContentPageState`、`didUpdateWidget`、`ref.listen`、`setState`。

**url 变化的重置**：`galleryPageAccumulatorProvider(url)` 中 url 变化时 Riverpod 自动创建新实例并 `build`，状态自然归零。`InfiniteScrollView` 的 `didUpdateWidget` 检测到 itemCount 从 >0 → 0 时自动触发新的 `requestRefresh`。

### 修改文件清单

| 文件 | 修改 |
|------|------|
| `lib/presentation/widgets/infinite_scroll_view.dart` | 重构为自包含分页组件，内化管理 RefreshController 和 SmartRefresher 生命周期 |
| `lib/presentation/pages/js_gallery/gallery_content_page.dart` | 降级为 `ConsumerWidget`，移除 State、ref.listen、RefreshController，只传回调给 InfiniteScrollView |

### 不改动的文件

- `lib/presentation/pages/rust_daily/rust_daily_list_tab.dart` — 暂不动，等 GalleryContentPage 验证通过后再跟进
- `lib/presentation/providers/js_gallery/gallery_page_accumulator_provider.dart` — 接口不变

## 验证

1. `flutter analyze` 零告警
2. GalleryPage：首次加载、下拉刷新、上拉加载更多、切换 Tab 均正常
3. RustDailyListTab 不受影响（仍使用旧版 InfiniteScrollView API）

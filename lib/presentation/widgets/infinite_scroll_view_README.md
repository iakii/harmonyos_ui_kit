# InfiniteScrollView

基于 `SmartRefresher` 封装的无限滚动列表视图，支持下拉刷新和上拉加载更多，自带应用生命周期管理。

## 两种模式

### `InfiniteScrollView()` — children 模式（旧版，向后兼容）

基于 `children` 的简单列表，刷新/加载状态由外部管理。

```dart
InfiniteScrollView(
  children: [/* 列表组件 */],
  onRefresh: () async { await fetchData(); },
  onLoadMore: () { loadNextPage(); },
  hasMore: hasMore,
  isLoadingMore: isLoadingMore,
  controller: scrollController,
  refreshController: refreshController,
  autoRequestRefresh: true,
)
```

### `InfiniteScrollView.paginated()` — 自包含分页模式（推荐）

**内部管理 `RefreshController` 和 SmartRefresher 状态转换**，外部只需提供异步回调和数据。

```dart
InfiniteScrollView.paginated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
  onRefresh: () async { await refreshData(); },
  onLoadMore: () async { await loadNextPage(); },
  hasMore: hasMore,
  error: error,
  headerItems: [/* 固定在列表上方的组件 */],
  footerItems: [/* 固定在列表下方的组件 */],
  contentSliverBuilder: (builder, count) => SliverStaggeredGrid.countBuilder(
    crossAxisCount: crossAxisCount,
    itemCount: count,
    itemBuilder: builder,
    staggeredTileBuilder: (index) => StaggeredTile.fit(1),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  ),
)
```

---

## API 参考（paginated 模式）

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `itemCount` | `int` | ✅ | 列表项数量 |
| `itemBuilder` | `IndexedWidgetBuilder` | ✅ | 列表项构造器 `(BuildContext, int) → Widget` |
| `onRefresh` | `Future<void> Function()` | ✅ | 下拉刷新回调。内部 `await` 完成后自动调用 `refreshCompleted()` |
| `onLoadMore` | `Future<void> Function()` | ✅ | 上拉加载更多回调。内部 `await` 完成后自动 `loadComplete`/`loadNoData`/`loadFailed` |
| `hasMore` | `bool` | ✅ | 是否还有更多页。为 `false` 时上拉显示"已加载全部" |
| `error` | `Object?` | ❌ | 当前错误。非 `null` 且 `itemCount == 0` 时触发刷新失败状态 |
| `headerItems` | `List<Widget>` | ❌ | 固定在列表上方的组件（默认 `[]`） |
| `footerItems` | `List<Widget>` | ❌ | 固定在列表下方的组件（默认 `[]`） |
| `controller` | `ScrollController?` | ❌ | 外部 `ScrollController`，用于共享滚动位置 |
| `contentSliverBuilder` | `Widget Function(IndexedWidgetBuilder, int)?` | ❌ | 自定义内容 sliver 构建器。不传时用 `SliverToBoxAdapter` 逐项包裹 |
| `autoLoad` | `bool` | ❌ | 初始化时是否自动加载第一页（默认 `true`） |

### `contentSliverBuilder`

注入自定义 sliver 布局，接收 `(itemBuilder, itemCount)` 返回一个 sliver widget。

默认行为（不传时）：
```dart
for (final item in items)
  slivers.add(SliverToBoxAdapter(child: item));
```

常用场景 — 网格布局：
```dart
contentSliverBuilder: (builder, count) => SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  ),
  delegate: SliverChildBuilderDelegate(builder, childCount: count),
)
```

常用场景 — 瀑布流布局（使用 `SliverStaggeredGrid`）：
```dart
contentSliverBuilder: (builder, count) => SliverPadding(
  padding: EdgeInsets.symmetric(horizontal: 12),
  sliver: SliverStaggeredGrid.countBuilder(
    crossAxisCount: crossAxisCount,
    itemCount: count,
    itemBuilder: builder,
    staggeredTileBuilder: (index) => StaggeredTile.fit(1),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  ),
)
```

---

## 内部行为

### 生命周期

```
initState
  └─ autoLoad=true → addPostFrameCallback → RefreshController.requestRefresh()
       └─ SmartRefresher.onRefresh → _onRefresh()
            └─ await widget.onRefresh()
                 ├─ 成功 → refreshCompleted()
                 │         ├─ hasMore=true  → resetNoData()
                 │         └─ hasMore=false → loadNoData()
                 └─ 失败 → refreshFailed()

上拉加载
  └─ SmartRefresher.onLoading → _onLoading()
       ├─ hasMore=false → loadNoData()
       ├─ paginated 模式
       │    └─ await widget._onLoadMoreAsync()
       │         ├─ 成功 → hasMore ? loadComplete() : loadNoData()
       │         └─ 失败 → loadFailed()
       └─ children 模式
            └─ widget._onLoadMoreVoid() → 外部管理 isLoadingMore

didUpdateWidget（paginated 模式）
  └─ itemCount 从 >0 → 0（URL 变化重置）
       └─ resetNoData() → addPostFrameCallback → requestRefresh()
```

### 应用生命周期

App 进入后台（`paused`/`inactive`/`hidden`）时暂停刷新/加载操作，回到前台（`resumed`）时恢复。

---

## 完整示例

### 与 Riverpod 集成（推荐模式）

```dart
class PhotoGallery extends ConsumerWidget {
  const PhotoGallery({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 分页累积状态由 Provider 管理
    final acc = ref.watch(galleryPageAccumulatorProvider(url));
    final state = acc.valueOrNull;
    final items = state?.items ?? [];
    final hasMore = state?.hasMore ?? false;
    final hasError = state?.error != null && items.isEmpty;

    return InfiniteScrollView.paginated(
      itemCount: items.length,
      itemBuilder: (context, index) => PhotoCard(item: items[index]),
      onRefresh: () => ref.read(accumulator.notifier).refresh(),
      onLoadMore: () => ref.read(accumulator.notifier).loadNext(),
      hasMore: hasMore,
      error: hasError ? state!.error : null,
      headerItems: [
        if (hasError)
          ErrorWidget(message: state!.error.toString(), onRetry: /* ... */),
      ],
      footerItems: const [SizedBox(height: 80)],
    );
  }
}
```

### 注意事项

1. **URL 变化自动重置**：将 url 作为参数传给 provider 时，Riverpod 自动按 key 缓存。url 变化 → 新 provider 实例 → `build()` 返回空状态 → `itemCount` 变为 0 → `InfiniteScrollView` 检测到并自动触发 `requestRefresh()`。
2. **错误处理**：`error` 参数只控制 loading/refreshing 状态的错误反馈。列表已有数据时新加载出错，不会用错误页覆盖已有列表（错误通过刷新头/加载尾的 `failedText` 展示）。
3. **`onLoadMore` 必须异步**：paginated 模式下 `onLoadMore` 的 `Future` 完成或异常后，组件自动决定调用 `loadComplete()` / `loadNoData()` / `loadFailed()`。

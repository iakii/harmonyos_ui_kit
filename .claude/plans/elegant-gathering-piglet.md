# GalleryDetail 分页字段新增计划

## Context

当前 `GalleryDetail` 实体只有 `list` 和 `current` 两个字段，详情页（DetailPage）是单次加载模式，没有分页能力。而图集列表页（Gallery）已有完整的分页累积模式（`GalleryPageData` → `GalleryPageAccumulator` → `InfiniteScrollView.paginated`）。

需要为详情页增加分页支持：JS 端 `fetchDetails()` 返回数据中可能包含 `totalPage` 和 `nextPageUrl`，Dart 端解析后实现页面级别的分页累积。

**现状：`DetailLoadState` 存在两份重复代码：**
- Entity 版：`lib/domain/entities/detail_load_state.dart`（repository 层使用）
- Provider 本地版：`lib/presentation/providers/js_gallery/detail_provider.dart:17-54`（UI 层使用）
- 本次只新增字段，不做去重重构

## 分页判断规则

| 条件 | `hasMore` | 下一页 URL |
|------|-----------|-----------|
| 两者皆为 null | `false`（无分页） | N/A |
| `nextPageUrl` 非 null | `true` | 直接用 `nextPageUrl` |
| 仅 `totalPage` 非 null | `current < totalPage` | 从 `lastLoadedUrl` + `?page=N` 构造 |
| 两者都非 null | `true`（优先 nextPageUrl） | 用 `nextPageUrl` |

## 实现步骤

### Step 1: 修改 `GalleryDetail` 实体

**文件：** `lib/domain/entities/gallery_detail.dart`

- 新增 `int? totalPage` 和 `String? nextPageUrl` 字段（均为可选，默认 null）
- 新增 `bool get hasMore` getter
- `fromJson` 中解析这两个字段（不存在时保持 null）

```dart
class GalleryDetail {
  final List<DetailItem> list;
  final int current;
  final int? totalPage;       // 新增：总页数，null 表示未提供
  final String? nextPageUrl;  // 新增：下一页 URL，null 表示未提供

  /// 是否有更多分页数据。
  /// 两者都为 null → 无分页；任意一个非 null 即启用分页。
  bool get hasMore =>
      nextPageUrl != null || (totalPage != null && current < totalPage!);
}
```

### Step 2: 更新两份 `DetailLoadState`

**文件 A：** `lib/domain/entities/detail_load_state.dart`（entity 版，repository 使用）

- 新增 `int? totalPage`、`String? nextPageUrl`、`int current` 字段
- 新增 `bool get hasMore` getter
- 所有工厂构造函数增加默认值（`null` / `1`），保持向后兼容

**文件 B：** `lib/presentation/providers/js_gallery/detail_provider.dart`（provider 本地版）

- 同样新增上述字段和 `hasMore` getter
- `_emitFinal` 方法中：解析 `GalleryDetail` 后，将 `totalPage`、`nextPageUrl`、`current` 传入 `DetailLoadState.done()`

### Step 3: 创建 `DetailAccumulatorState` 实体

**新文件：** `lib/domain/entities/detail_accumulator_state.dart`

仿照 `GalleryAccumulatorState`，包含：
- `items`（累积的全部 DetailItem）
- `currentPage`（已加载的最后一页，0=未开始）
- `totalPage`、`nextPageUrl`（来自最后一页响应）
- `isLoading`、`error`、`hasLoaded`
- `lastLoadedUrl`（用于构造下一页 URL，当只有 totalPage 时）
- `hasMore` getter
- `empty()` 工厂、`copyWith()` 方法

### Step 4: 创建 `DetailPageAccumulator` Provider

**新文件：** `lib/presentation/providers/js_gallery/detail_page_accumulator_provider.dart`

仿照 `GalleryPageAccumulator`，使用 `@riverpod class ... extends _$...`（`AutoDisposeAsyncNotifier`）：

- `build(String url)`：返回 `DetailAccumulatorState.empty()`，并自动触发首页加载
- `loadNext()`：判断 `hasMore`，构造下一页 URL，spawn isolate 加载，累积结果
- `refresh()`：重置状态，重新加载首页
- 内部 `_loadSinglePage(String url)`：spawn isolate 执行 `_detailWorker`，忽略进度消息，仅等待最终结果返回 `GalleryDetail`

URL 构造逻辑（当只有 `totalPage` 无 `nextPageUrl` 时）：
```dart
String _buildNextPageUrl(String baseUrl, int nextPage) {
  final uri = Uri.parse(baseUrl);
  final newQuery = Map<String, String>.from(uri.queryParameters);
  newQuery['page'] = nextPage.toString();
  return uri.replace(queryParameters: newQuery).toString();
}
```

### Step 5: 更新仓库实现（兼容性）

**文件：** `lib/data/repositories/js_gallery_repository_impl.dart`

`_emitFinal` 方法中同样将新字段传入 `DetailLoadState.done()`。

### Step 6: 重写详情页 UI

**文件：** `lib/presentation/pages/js_gallery/detail/detail_page.dart`

- 从 `HookConsumerWidget` 改为 `ConsumerWidget`
- `ref.watch` 目标从 `detailLoadProvider(url)` 改为 `detailPageAccumulatorProvider(url)`
- 用 `InfiniteScrollView.paginated` 替代 `DetailList`
- `onRefresh` → `provider.notifier.refresh()`
- `onLoadMore` → `provider.notifier.loadNext()`
- `hasMore` → `state.hasMore`
- 加载中/错误/空状态通过 `headerItems` 处理

**文件：** `lib/presentation/pages/js_gallery/detail/detail_list.dart`

- 删除（不再使用，`InfiniteScrollView.paginated` 已包含列表渲染）

### Step 7: 运行 build_runner 重新生成代码

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 文件变更清单

| 文件 | 操作 | 复杂度 |
|------|------|--------|
| `lib/domain/entities/gallery_detail.dart` | 修改 | 低 |
| `lib/domain/entities/detail_load_state.dart` | 修改 | 低 |
| `lib/domain/entities/detail_accumulator_state.dart` | **新建** | 中 |
| `lib/presentation/providers/js_gallery/detail_provider.dart` | 修改 | 中 |
| `lib/presentation/providers/js_gallery/detail_page_accumulator_provider.dart` | **新建** | 高 |
| `lib/presentation/providers/js_gallery/detail_page_accumulator_provider.g.dart` | 自动生成 | — |
| `lib/data/repositories/js_gallery_repository_impl.dart` | 修改 | 低 |
| `lib/presentation/pages/js_gallery/detail/detail_page.dart` | 重写 | 高 |
| `lib/presentation/pages/js_gallery/detail/detail_list.dart` | 删除 | 低 |

## 边界情况处理

| 场景 | 处理方式 |
|------|---------|
| JS 不返回分页字段（旧版兼容） | `hasMore=false`，行为与现在完全一致 |
| 加载下一页时出错 | `error` 设到 state，已有数据保留，`InfiniteScrollView` 显示重试 |
| 快速连续调用 loadNext | `if (current.isLoading) return;` 守卫 |
| 页面离开时 dispose | `ref.onDispose` 中 kill isolate、关闭 ReceivePort |
| 空列表 | `hasLoaded=true && items.isEmpty` → 显示空状态 |
| 既有 nextPageUrl 又有 totalPage | 优先使用 nextPageUrl |

## 验证方法

1. 运行 `flutter analyze` 确认无静态错误
2. 运行 `dart run build_runner build --delete-conflicting-outputs` 确认代码生成成功
3. 检查无分页字段的详情页仍正常加载（向后兼容）
4. 检查有分页字段的详情页支持加载更多

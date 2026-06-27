# 搜索功能实现计划

## Context

JS Gallery 的搜索入口已预留（`GalleryBody` AppBar 的放大镜图标 → `showSearchPanel`），但 `SearchPanel` 目前是 `Placeholder()` 空壳。部分 JS 客户端（`jdtaotu.cjs`、`wallhaven.cjs`）已实现 `client.search(keyword, page)` 方法，返回格式与 `fetchGallery` 一致（`{ list, totalPage, current }`）。需要打通 Dart → JS → UI 的完整链路。

## 实现步骤

### Step 1: Repository 层 — 添加 `search` 方法

**`lib/domain/repositories/js_gallery_repository.dart`** — 接口新增：
```dart
Future<Result<GalleryPageData>> search({
  required String keyword,
  required int page,
});
```

**`lib/data/repositories/js_gallery_repository_impl.dart`** — 实现，参照 `getPage` 模式调用 `client.search(keyword, page)`。

### Step 2: Provider 层 — 添加搜索 Provider

**新建 `lib/presentation/providers/js_gallery/search_page_accumulator_provider.dart`**：
- `searchProvider` — 调用 `repo.search(keyword, page)`（参照 `galleryProvider`）
- `SearchPageAccumulator` — 封装分页累积逻辑（参照 `GalleryPageAccumulator`），复用 `GalleryAccumulatorState`

> 为什么不复用 `GalleryPageAccumulator`？因为数据源不同：gallery 调用 `repo.getPage(url)`，search 调用 `repo.search(keyword)`，分开更清晰。

**修改 `lib/presentation/providers/js_gallery/repository_providers.dart`** — 无需修改（`jsGalleryRepositoryProvider` 已存在，search 直接复用它）。

### Step 3: UI 层 — 实现 SearchPanel

**修改 `lib/presentation/pages/js_gallery/widgets/search_panel.dart`**：
- 顶部：搜索输入框（`TextField` + 搜索/清除图标）
- 主体：复用 `InfiniteScrollView` + `SliverStaggeredGrid`（与 `GalleryContentPage` 相同布局）
- 通过 `SearchPageAccumulator` 获取数据
- 状态覆盖：loading spinner、空结果提示、错误重试、无更多数据
- 搜索触发：输入提交后调用 `refresh()` 重新加载

### Step 4: 运行 `build_runner` 生成 `.g.dart`

搜索 provider 使用 `@riverpod` 注解，需要运行 codegen。

## 关键设计决策

1. **复用 `GalleryAccumulatorState`** — `client.search` 返回格式与 `fetchGallery` 完全相同，无需新建状态类。
2. **复用 `GridItemCard`** — 搜索结果卡片与图集列表使用相同的展示组件。
3. **每次搜索重置状态** — 修改 keyword 时 provider 自动重建，数据自然清零。
4. **优雅降级** — 如果 JS 客户端未实现 `search` 方法，JS 引擎会抛出错误，在 UI 层捕获显示。

## 涉及文件

| 操作 | 文件 |
|------|------|
| 修改 | `lib/domain/repositories/js_gallery_repository.dart` |
| 修改 | `lib/data/repositories/js_gallery_repository_impl.dart` |
| **新建** | `lib/presentation/providers/js_gallery/search_page_accumulator_provider.dart` |
| 修改 | `lib/presentation/pages/js_gallery/widgets/search_panel.dart` |

## 验证

1. 运行 `dart run build_runner build --delete-conflicting-outputs` 生成 `.g.dart`
2. 运行 `flutter analyze` 确认无静态错误
3. 启动应用 → 进入图集页 → 点击搜索图标 → 输入关键词 → 确认搜索结果正确展示、分页加载、空状态提示正常

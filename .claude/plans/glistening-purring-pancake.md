# 修复「加载更多」逻辑

## Context

**问题**：Rust Daily 列表页的「上拉加载更多」分页逻辑有 bug，翻页后新数据**替换**了旧数据，而非**追加**。

**根因分析**：

`rust_daily_provider.dart` 的 `fetch()` 方法中（约71-90行），存在两个问题：

1. **积累判断永远为 true**：因为 family provider 按 page 分 key，每次翻页创建新实例，`build()` 返回 `RustDailyPageData.empty()`（`currentPage: 1`）。所以 `fetch()` 中的 `state.currentPage == 1` 始终为 true：
   ```dart
   final items = state.currentPage == 1
       ? liItems             // ← 永远走这里，只用当前页数据
       : [...state.liItems, ...liItems];  // ← 永远不会执行
   ```

2. **状态更新被条件守卫**：`if (state.currentPage == 1)` 守卫限制了状态更新——虽然后续刷新后也会进，但 `liItems` 只含当前页，不是累积结果。

另外 widget 层（`rust_daily_list_tab.dart`）旧的 `ref.listen` 累积逻辑被注释掉了（约115-140行），当前使用 `ref.watch` + `.select()` 直接从 provider 取 HTML 显示，没有做跨页累积。

**解决方案**：让 provider 只负责返回单页数据，累积由 widget 层管理。

---

## 改动文件

### 1. `lib/presentation/providers/rust_daily/rust_daily_provider.dart`

**`fetch()` 方法 — list 分支简化**：

- 移除积累逻辑（`items = state.currentPage == 1 ? ... : [...]`）
- 移除 `if (state.currentPage == 1)` 状态更新守卫
- 列表模式下 `html` 留空（由 widget 层累积后构建），仅保留 `liItems`、`totalPage`、`currentPage`
- 始终执行 `state = state.copyWith(...)`，确保 watch/listen 能收到更新

```dart
// 改前（约71-90行）
final items = state.currentPage == 1
    ? liItems
    : [...state.liItems, ...liItems];
html = '''<div style="padding:16px">${items.join('\n')}</div>''';
if (state.currentPage == 1) {
  state = state.copyWith(loading: false, html: html, ...);
}

// 改后
// 列表模式不构建 html，仅存当前页 liItems；累积交由 widget 层处理
state = state.copyWith(
  loading: false,
  html: '',  // widget 层累积后自行构建
  liItems: liItems,
  totalPage: totalPage,
  currentPage: params.page,
);
```

### 2. `lib/presentation/pages/rust_daily/rust_daily_list_tab.dart`

**Widget 层增加累积状态与监听**：

- 新增 `List<String> _accumulatedItems = []` 字段跟踪全部页面累积的 li 条目
- 新增 `int _totalPage = 1` 字段跟踪总页数，用于计算 `hasMore`
- 恢复 `ref.listen` 逻辑（替代当前 `ref.watch` + `.select()` 方式）：
  - `next.currentPage == 1` → 替换 `_accumulatedItems`
  - `next.currentPage > 1` → 追加到 `_accumulatedItems`，并重置 `_isLoadingMore = false`
  - 每次都从 `_accumulatedItems` 重新构建 `_accumulatedHtml`
  - 跳过 `loading == true` 或 `liItems.isEmpty` 的中间态
- 用本地 `_accumulatedHtml` 替代 `ref.watch(...html)` 作为显示内容
- 用 `_totalPage` 和 `_currentPage` 计算 `hasMore`，替代 `ref.watch(...hasMore)`
- `onLoadMore()` 中增加错误处理，fetch 出错时重置 `_isLoadingMore`

---

## 不影响的部分

- `rust_daily_detail_page.dart` — 使用 `type: 'detail'` 分支，不受影响
- `RustDailyPageData` 实体 — 无需改动
- `InfiniteScrollView` — 无需改动，子组件管理逻辑不变

---

## 验证方法

1. 运行 `flutter analyze` 确保无静态分析错误
2. 编译运行应用
3. 打开 Rust Daily 列表页，下拉刷新验证首页加载
4. 上拉触底，验证新页数据是否正确**追加**（非替换）
5. 再次下拉刷新，验证数据重置回首页
6. 切换到其他 Tab 再切回，验证数据和滚动位置保持

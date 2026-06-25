# Rust Daily 架构重构：PageView + KeepAlive 分离

## Context

当前 `RustDailyPage`（353 行）混合了两个职责：
1. **Tab 容器**：HosTabBar + switchTab 状态管理
2. **列表内容**：provider 数据获取、分页、InfiniteScrollView

Tab 切换时所有状态被销毁重建（reset page/items/cache），切换回之前的 tab 需要重新加载。

**目标**：拆分职责，用 `PageView` + `AutomaticKeepAliveClientMixin` 实现 tab 页面缓存。

## 新架构

```
RustDailyPage (HookConsumerWidget)          ← 纯容器：TabBar + PageView
├── PageView (PageController 同步 HosTabBar)
│   ├── Page 0: RustDailyListTab(tab: tabs[0])   ← KeepAlive
│   ├── Page 1: RustDailyListTab(tab: tabs[1])   ← KeepAlive
│   └── Page 2: RustDailyListTab(tab: tabs[2])   ← KeepAlive

RustDailyDetailPage (HookConsumerWidget)    ← 详情页：纯 HTML 展示
```

## 文件变更

### 1. 新建 `lib/pages/rust_daily_list_tab.dart`

`RustDailyListTab` — `ConsumerStatefulWidget` + `AutomaticKeepAliveClientMixin`

```
参数：
  RustDailyTab tab         ← 包含 url / label / key / icon

内部状态（State 中）：
  int currentPage = 1
  List<String> accumulatedItems = []
  RustDailyPageData? cachedData
  RefreshController refreshController  ← 自己管理生命周期
  ScrollController scrollController

行为：
  - ref.watch(provider(params)) → 数据获取
  - InfiniteScrollView → 下拉刷新 + 加载更多
  - onTapUrl → router.push('/rust', extra: {type:'detail', url, title})
  - AutomaticKeepAliveClientMixin → wantKeepAlive = true
  - dispose → refreshController.dispose(), scrollController.dispose()
```

> **为什么用 `ConsumerStatefulWidget` 而不是 `HookConsumerWidget`**：`AutomaticKeepAliveClientMixin` 必须用在 `State` 上。hooks 没有对应的 keep-alive hook。

### 2. 新建 `lib/pages/rust_daily_detail_page.dart`

`RustDailyDetailPage` — `HookConsumerWidget`

```
参数：
  String url               ← 文章详情 URL
  String title             ← 页面标题

行为：
  - params = RustDailyParams(url, type:'detail', page:1)
  - ref.watch(provider) → 获取 HTML
  - HosPage + HtmlWidget 展示，无分页/刷新
  - 跟 ListTab 一样使用 rustDailyProvider
```

> 从原 `RustDailyPage` 的 detail 分支中抽取出来。

### 3. 重构 `lib/pages/rust_daily.dart`

`RustDailyPage` — `HookConsumerWidget`

```
参数：
  无（仅作为默认列表入口，不再接收 url/type/title）

内部状态：
  selectedTabIndex  useState(0)
  pageController    useRef(PageController())
  listTabs          RustDailyTab.defaultListTabs()

布局：
  Column([
    HosTabBar(
      tabs: listTabs.map(label),
      selectedIndex: selectedTabIndex,
      onChanged: (i) => pageController.animateToPage(i),
    ),
    Expanded(
      PageView.builder(
        controller: pageController,
        onPageChanged: (i) => selectedTabIndex.value = i,
        itemCount: 3,
        itemBuilder: (ctx, i) => RustDailyListTab(tab: listTabs[i]),
      ),
    ),
  ])

  ← 不需要 RefreshController、pagination、provider 等
```

> `_BackToTopButton` 移到 `RustDailyListTab` 内部。

### 4. 更新 `lib/router.dart`

`/rust` 路由改为根据 `type` 分发：

```dart
GoRoute(
  path: '/rust',
  builder: (context, state) {
    if (state.extra == null) return const RustDailyPage();
    final extra = state.extra as Map<String, dynamic>;
    final type = extra['type'] as String?;
    final url = extra['url'] as String?;
    final title = extra['title'] as String? ?? '';
    if (type == 'detail' && url != null) {
      return RustDailyDetailPage(url: url, title: title);
    }
    return const RustDailyPage();
  },
),
```

### 5. `lib/pages/rust_daily.dart` 中移除的内容

| 移除 | 原因 |
|------|------|
| `url` / `type` / `title` 构造参数 | 容器不再处理业务数据 |
| `currentPage` / `accumulatedItems` / `cachedData` | 移到 `RustDailyListTab` |
| `refreshController` | 移到 `RustDailyListTab` |
| `switchTab()` | PageView 自动切换 |
| `useEffect([url])` | 不再需要 |
| `effectiveUrl` / `currentTabKey` | 移到 `RustDailyListTab` |
| `params` / `asyncData` / `ref.listen` / `provider` | 移到 `RustDailyListTab` |
| `onRefresh` / `onLoadMore` | 移到 `RustDailyListTab` |
| `_buildContent` 方法 | 移到 `RustDailyListTab`（列表）和 `RustDailyDetailPage`（详情） |
| `_BackToTopButton` | 移到 `RustDailyListTab` |

## 边界情况

| 场景 | 行为 |
|------|------|
| 切换到新 tab | PageView 滑动，新 tab 首次加载数据 |
| 切回之前的 tab | KeepAlive 保持，数据和滚动位置不变 |
| 下拉刷新 | 当前 tab 重新加载，不影响其他 tab |
| 加载更多 | 当前 tab 追加条目 |
| 点击文章 → detail | push 到新路由，`RustDailyDetailPage` 加载详情 |
| detail 返回 list | PageView 状态保持（KeepAlive），无需重新加载 |
| 快速滑动 | PageView 懒加载 + 缓冲，只创建当前 + 相邻页 |

## 验证

```bash
flutter analyze lib/pages/rust_daily.dart lib/pages/rust_daily_list_tab.dart lib/pages/rust_daily_detail_page.dart lib/router.dart
```

功能验证：
1. 默认 tab（综合）正常加载
2. 左右滑动切换 tab → 每个 tab 独立加载数据
3. 切回之前的 tab → 滚动位置和内容保持
4. 点击文章 → 进入详情页 → 返回 → tab 状态保持
5. 下拉刷新无异常
6. 加载更多无异常

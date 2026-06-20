# 封装 meitule.js 的 Riverpod Provider 及图集页面

## Context

将 `assets/js/meitule.js` 的 JS 图集解析能力封装为可复用的 Riverpod provider。页面上根据 `pluginInfo` 生成菜单和标题，通过 `getPage` 获取图集列表并用 `GridView.builder` 展示，点击条目调用 `getDetails` 加载详情页。现有 `js_parse.dart` 使用 `signals` 库作为 demo，本次新建的代码全部使用 Riverpod（项目已有 `hooks_riverpod` + `ProviderScope`）。

## 新增/修改文件

### 1. `lib/models/plugin/plugin_info.dart` (新建)

```dart
class MenuItem { String label; String path; }
class PluginInfo { String type, version, website, name; List<MenuItem> menus; }
```
均带 `fromJson` / `toJson`。

### 2. `lib/models/plugin/gallery_item.dart` (新建)

```dart
class GalleryItem { String link, cover, title; }
class GalleryPageData { List<GalleryItem> list; int totalPage, current; bool get hasMore; }
class DetailItem { String? cover, href, title; }
class GalleryDetail { List<DetailItem> list; int current; }
```
均带 `fromJson`。

### 3. `lib/providers/js_engine_provider.dart` (新建) — 公用共享 Provider

```dart
final jsEngineProvider = FutureProvider<JsEngine>((ref) async {
  // 用 rootBundle 加载 meitule.js（无需 BuildContext）
  final jsFiles = await rootBundle.loadString('assets/js/meitule.js');
  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: await JsBuiltinOptions.web(), // Console + Fetch
      info: 'meitule',
    ),
    modules: [JsModule(name: 'client', source: jsFiles)],
  );
  ref.onDispose(() => engine.close());
  return engine;
});
```

### 4. `lib/providers/plugin_info_provider.dart` (新建)

```dart
final pluginInfoProvider = FutureProvider<PluginInfo>((ref) async {
  final engine = await ref.watch(meituleJsEngineProvider.future);
  final result = engine.eval(code: '''
    (async () => {
      const { default: client } = await import('client');
      return client.pluginInfo;
    })()
  ''');
  final jsonStr = result.asStringSync;
  if (jsonStr == null) throw ParseException('pluginInfo 返回非字符串');
  return PluginInfo.fromJson(jsonDecode(jsonStr));
});
```

### 5. `lib/providers/gallery_provider.dart` (新建)

```dart
final galleryProvider = FutureProvider.family<GalleryPageData, ({String url, int page})>(
  (ref, params) async {
    final engine = await ref.watch(meituleJsEngineProvider.future);
    final {url, page} = params;
    final safeUrl = jsonEncode(url); // 安全转义
    final result = engine.eval(code: '''
      (async () => {
        const { default: client } = await import('client');
        return await client.getPage($safeUrl, $page);
      })()
    ''');
    final jsonStr = result.asStringSync;
    if (jsonStr == null || jsonStr == 'undefined') {
      throw NetworkException('获取图集数据失败: $url');
    }
    return GalleryPageData.fromJson(jsonDecode(jsonStr));
  },
);
```

### 6. `lib/providers/detail_provider.dart` (新建)

```dart
final detailProvider = FutureProvider.family<GalleryDetail, String>(
  (ref, url) async {
    final engine = await ref.watch(meituleJsEngineProvider.future);
    final safeUrl = jsonEncode(url);
    final result = engine.eval(code: '''
      (async () => {
        const { default: client } = await import('client');
        return await client.getDetails($safeUrl, true);
      })()
    ''');
    final jsonStr = result.asStringSync;
    if (jsonStr == null || jsonStr == 'undefined') {
      throw NetworkException('获取详情失败: $url');
    }
    return GalleryDetail.fromJson(jsonDecode(jsonStr));
  },
);
```

### 7. `lib/pages/js/gallery_page.dart` (新建)

`HookConsumerWidget`:
- `ref.watch(pluginInfoProvider)` → 动态 AppBar 标题 + HosTabBar 菜单
- `useState(0)` → 当前选中的 tab index
- `useState(1)` → 当前页码
- `ref.watch(galleryProvider((url: currentUrl, page: currentPage)))` → 图集数据
- `AsyncValueWidget` 渲染三态（loading / error / data）
- data 态：`GridView.builder(crossAxisCount: 2, ...)`，每个 item 是 HosCard 包裹的封面图 + 标题
- 点击 item → `context.push('/meitule/detail', extra: item.link)`
- 底部页码控制（上一页/下一页）

### 8. `lib/pages/js/detail_page.dart` (新建)

`HookConsumerWidget`:
- 接收 `url`（从 `state.extra as String`）
- `ref.watch(detailProvider(url))` → 详情数据
- `AsyncValueWidget` 渲染
- data 态：`ListView.builder` 展示图片 + 标题

### 9. `lib/router.dart` (修改)

在 `ShellRoute` 的 `routes` 中添加：
```dart
GoRoute(
  path: '/meitule',
  builder: (context, state) => const GalleryPage(),
  routes: [
    GoRoute(
      path: 'detail',
      builder: (context, state) => DetailPage(url: state.extra as String),
    ),
  ],
),
```

### 10. `lib/pages/layout.dart` (修改)

底部导航栏新增一项：
```dart
HosBottomNavItem(icon: HMIcons.image, label: '图集'),
```
对应路由 `'/meitule'`。

## Provider 依赖图

```
jsEngineProvider (FutureProvider)  ← 公用、共享
    ├── pluginInfoProvider (FutureProvider)
    ├── galleryProvider.family (FutureProvider.family)
    └── detailProvider.family (FutureProvider.family)
```

## 设计要点

- **共享引擎**: `jsEngineProvider` 是唯一的 `FutureProvider<JsEngine>`，所有其他 provider 通过 `ref.watch(future)` 依赖它，确保整个应用只有一个 JsEngine 实例
- **字符串安全**: eval 中拼接的 URL 使用 `jsonEncode()` 转义，防止注入
- **网络失败处理**: meitule.js 在 fetch 失败时只 `console.log` 不抛异常，返回 `undefined`；Dart 端检测到 `null` 或 `"undefined"` 时抛出 `NetworkException`
- **分页**: `galleryProvider.family` 按 `(url, page)` 组合作为 key，切换 tab 时自动重建

## 验证

1. `flutter analyze` 无新增错误
2. 启动应用，底部导航栏出现"图集"tab
3. 点击"图集"进入 MeituGalleryPage，看到从 pluginInfo 加载的标题和菜单
4. 切换菜单 tab，GridView 刷新对应内容
5. 点击 grid item 跳转详情页，显示 getDetails 加载的图片

## 不在此范围

- 图片缓存（后续可用 `cached_network_image`）
- 离线/本地数据持久化
- JS eval 超时机制（后续按需添加）

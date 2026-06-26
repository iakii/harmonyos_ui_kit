# 实现 intro_provider 状态处理 + intro_page UI 视图

## Context

`fetchIntro` 已在 JS 端实现，但 Dart 端两处需要同步适配：
1. `intro_provider.dart` — `refresh()` 只调用 JS 但不解析结果更新状态；`JsInfoData` 字段与 `fetchIntro` 返回不匹配
2. `js_intro.dart` — 仅占位文本，需要完整 UI 视图

## 修改文件

| 文件 | 操作 |
|------|------|
| `lib/presentation/providers/js_gallery/intro_provider.dart` | 重写 `JsInfoData` → `IntroData`，`refresh()` 解析 JSON 并更新 state |
| `lib/presentation/providers/js_gallery/intro_provider.g.dart` | 重新生成（`dart run build_runner build --delete-conflicting-outputs`） |
| `lib/presentation/pages/js_gallery/intro/js_intro.dart` | 完整 UI：加载/错误/数据三态 + 漫画详情视图 |

## 1. intro_provider.dart 改动

### 1.1 替换 JsInfoData → IntroData

```dart
class IntroData {
  final String title;
  final String cover;
  final String author;
  final String category;
  final String status;
  final String description;
  final List<DetailItem> tags;
  final List<DetailItem> list;  // 章节列表

  const IntroData({...});
  factory IntroData.fromJson(Map<String, dynamic> json) => IntroData(
    title: json['title'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    author: json['author'] as String? ?? '',
    category: json['category'] as String? ?? '',
    status: json['status'] as String? ?? '',
    description: json['description'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>?)?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    list: (json['list'] as List<dynamic>?)?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
  factory IntroData.empty() => const IntroData(...);
}
```

### 1.2 修复 refresh() 方法

- `jsonDecode(jsonStr)` 解析结果
- `IntroData.fromJson()` 构建数据
- `state = introData` 更新状态，触发 UI 重建

### 1.3 provider 类型变更

- `JsIntro extends _$JsIntro` → 类型参数从 `JsInfoData` 变更为 `IntroData`
- 需要重新生成 `.g.dart`

## 2. js_intro.dart UI 设计

### 布局结构（自上而下滚动）

```
┌──────────────────────────┐
│ ← 漫画名                  │  HosAppBar (加粗省略)
├──────────────────────────┤
│  [封面大图]               │  ExtendedImage.network, fitWidth
│                          │
│  漫画名                   │  theme.typography.title2, 粗体
│                          │
│  ┌─ 信息卡片 ──────────┐ │
│  │ 作者：xxx             │ │  HosCard, Column of Rows
│  │ 分类：韓漫            │ │  每行：标签 (accent.08 背景) + 值
│  │ 状态：连载中          │ │
│  └──────────────────────┘ │
│                          │
│  [标签 chip] [标签 chip]   │  Wrap, 复用 grid_item_card.dart 的样式
│                          │
│  简介                     │  小节标题 (title3)
│  介绍文本...              │  body 字体
│                          │
│  章节列表 (共 N 话)       │  小节标题
│  ┌─ 章节卡片 ──────────┐ │
│  │ 第1话-...       ›   │ │  HosListItem, onTap 导航
│  │ 第2话-...       ›   │ │
│  └──────────────────────┘ │
└──────────────────────────┘
```

### 状态处理

- **加载中**: `Loading(size: 64)` 居中
- **加载失败**: `HosErrorState(message: ..., onRetry: ...)` 
- **加载成功但无数据**: `HosEmptyState(message: '暂无简介信息')`
- **有数据**: 完整渲染上述布局

### 核心实现要点

- 使用 `ref.watch(jsIntroProvider(widget.url))` 监听状态；首次加载用 `initState` / `ref.read().notifier.refresh()` 触发
- 避免每次 build 都调用 `refresh()`（当前代码的问题）
- 章节项 `onTap` → `context.push('/js_gallery_detail', extra: {title, url})`
- 封面图使用 `ExtendedImage.network` + `imageLoadState`（与 grid_item_card 一致）

## 3. 验证方式

1. `flutter analyze` 通过，无静态错误
2. 确认 `intro_provider.g.dart` 重新生成成功
3. 代码逻辑审查：`refresh()` 正确调用 `state =`；UI 三态覆盖完整

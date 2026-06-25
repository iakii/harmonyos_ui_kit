# 为 gallery_detail 和 gallery_page 添加回到顶部按钮

## Context

`RustDailyListTab` 已有"回到顶部"功能（`_BackToTopButton`），但 `GalleryContentPage` 和 `DetailPage` 都没有此功能。用户希望在 gallery_detail 和 gallery_page 中添加同样的回到顶部按钮。

## 改动方案

### 1. 提取 `BackToTopButton` 为共享公共组件

**新建**：`lib/presentation/widgets/back_to_top_button.dart`

将 `_BackToTopButton` 从 `rust_daily_list_tab.dart` 提取为公共类 `BackToTopButton`：
- 保持完全相同的 UI（圆形容器、`HMIcons.arrowshapeUpToLine`、缩放动画）
- 接受 `ScrollController` 参数
- 点击时 `animateTo(0, duration: 400ms, curve: easeInOut)`

### 2. 修改 `RustDailyListTab` 使用共享组件

**文件**：`lib/presentation/pages/rust_daily/rust_daily_list_tab.dart`

- 删除私有 `_BackToTopButton` 类和 `_BackToTopButtonState` 类
- 导入并使用共享 `BackToTopButton`

### 3. 为 `GalleryContentPage` 添加回到顶部

**文件**：`lib/presentation/pages/js_gallery/gallery/gallery_content_page.dart`

- 从 `ConsumerWidget` 改为 `ConsumerStatefulWidget`
- 在 state 中创建 `ScrollController`，添加滚动监听器，维护 `_showBackToTop` 状态
- 将 `ScrollController` 传给 `InfiniteScrollView.paginated(controller: ...)`
- 用 `Stack` 包裹 InfiniteScrollView，在 `_showBackToTop` 时显示 `Positioned` 的 `BackToTopButton`
- 在 `dispose` 中清理 listener 和 controller

### 4. 为 `DetailPage` 添加回到顶部

**文件**：`lib/presentation/pages/js_gallery/detail/detail_page.dart`

- 从 `ConsumerWidget` 改为 `ConsumerStatefulWidget`
- 在 state 中创建 `ScrollController`，添加滚动监听器，维护 `_showBackToTop` 状态
- 将 `ScrollController` 传给 `InfiniteScrollView.paginated(controller: ...)`
- 用 `Stack` 包裹 InfiniteScrollView，在 `_showBackToTop` 时显示 `Positioned` 的 `BackToTopButton`
- 在 `dispose` 中清理 listener 和 controller

### 复用模式

所有三处采用完全相同的模式：
```dart
// State 中
late final ScrollController _scrollController = ScrollController();
bool _showBackToTop = false;

void _onScroll() {
  if (!_scrollController.hasClients) return;
  final visible = _scrollController.position.pixels > 500;
  if (visible != _showBackToTop) {
    setState(() => _showBackToTop = visible);
  }
}

// Build 中
Stack(
  children: [
    InfiniteScrollView.paginated(controller: _scrollController, ...),
    if (_showBackToTop)
      Positioned(right: 16, bottom: 24, child: BackToTopButton(scrollController: _scrollController)),
  ],
)
```

## 影响范围汇总

| 文件 | 操作 |
|---|---|
| `lib/presentation/widgets/back_to_top_button.dart` | **新建** |
| `lib/presentation/pages/rust_daily/rust_daily_list_tab.dart` | 删除私有类，改用共享组件 |
| `lib/presentation/pages/js_gallery/gallery/gallery_content_page.dart` | ConsumerWidget→ConsumerStatefulWidget，添加回到顶部 |
| `lib/presentation/pages/js_gallery/detail/detail_page.dart` | ConsumerWidget→ConsumerStatefulWidget，添加回到顶部 |

## 验证

1. `flutter analyze` 无静态错误
2. 进入图集详情页（detail_page），向下滚动超过 500px 后出现回到顶部按钮，点击回到顶部
3. 进入图集内容页（gallery），同上效果
4. Rust Daily 页面的回到顶部按钮仍然正常工作

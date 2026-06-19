# HosAppBar 独立组件 + 沉浸光感

## Context

用户要求将 AppBar 从 `HosPage` 中提取为独立组件 `HosAppBar`，并实现与 `HosBottomNavigation` 一致的**沉浸光感**效果（BackdropFilter 毛玻璃 + 半透明背景）。

当前 AppBar 是 `HosPage` 内部的一个简单 opaque Container，缺少 HarmonyOS 标题栏的核心视觉特征（模糊材质、半透光感）。

参考：[华为官方标题栏设计指南](https://developer.huawei.com/consumer/cn/doc/design-guides/titlebar-0000001929628982)

## 设计规范（HDS 标题栏）

| 属性 | 规范值 |
|------|--------|
| 默认高度 | 56vp（单行） / 112vp（强调型） |
| 背景模糊 | 通用模糊（均匀）+ 渐变模糊（渐强/渐弱） |
| 下分割线 | 1px（非沉浸时）/ 模糊态带分割线 |
| 沉浸光感 | 半透明背景 + BackdropFilter 毛玻璃 |
| 提亮压暗 | 默认带有提亮压暗属性，提高背板通透度 |

## 实现方案

### 1. 新建 `lib/src/controls/navigation/app_bar.dart`

创建独立的 `HosAppBar` 组件，实现 `PreferredSizeWidget`，可直接作为 `Scaffold.appBar` 使用。

**API 设计**（与 `HosBottomNavigation` 对称）：

```dart
class HosAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HosAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.height = 56.0,
    this.immersive = true,
    this.blurSigmaX = 40.0,
    this.blurSigmaY = 40.0,
    this.backgroundColor,
    this.dividerColor,
  });
}
```

**核心逻辑**：与 `HosBottomNavigation` 相同的沉浸模式

```
build():
  1. 计算 effectiveBgColor:
     - 自定义 > immersive模式(浅色白0.85 / 深色暗0.85) > surfaceColor
  2. 构建内容 bar:
     - Container(height, bgColor, bottomBorder 1px)
     - child: NavigationToolbar(leading, middle=title, trailing=actions)
  3. 如果 immersive=true: ClipRect > BackdropFilter(ImageFilter.blur) > bar
  4. 返回 bar
```

**沉浸光感颜色**（与 BottomNavigation 相同）：
- 浅色: `Colors.white.withOpacity(0.85)`
- 深色: `Color(0xFF1E1E1E).withOpacity(0.85)`

### 2. 修改 `lib/src/controls/layout/page.dart`

- `HosPage` 内部使用 `HosAppBar` 替代原来的内联 Container
- 传递 `immersive` 参数（可配置，默认 true）
- `HosPage` 新增 `immersiveAppBar` 参数（默认 true）
- 兼容现有全部 API

### 3. 修改 `lib/harmonyos_ui.dart` 导出

新增 `export 'src/controls/navigation/app_bar.dart';`

### 4. 更新 `test/harmonyos_ui_test.dart`

- 新增 `HosAppBar` 测试组：渲染标题、leading、actions、沉浸/非沉浸模式

## 影响文件

| 文件 | 操作 |
|------|------|
| `lib/src/controls/navigation/app_bar.dart` | **新建** |
| `lib/src/controls/layout/page.dart` | 修改 — 使用 HosAppBar |
| `lib/harmonyos_ui.dart` | 新增 export |
| `test/harmonyos_ui_test.dart` | 新增测试 |

## 验证步骤

1. `flutter analyze` — 零问题
2. `flutter test` — 全部通过（新增 HosAppBar 测试 + 现有 HosPage 测试不退化）

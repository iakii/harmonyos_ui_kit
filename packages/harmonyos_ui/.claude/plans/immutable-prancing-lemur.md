# 拆分 harmony_immersive_glow.dart 组件

## Context

[harmony_immersive_glow.dart](../../../packages/harmonyos_ui/lib/src/widgets/harmony_immersive_glow.dart) 当前是一个约 1913 行的单文件，包含了枚举、数据模型、调色板、发光材质组件、导航栏组件及其所有私有辅助类。文件过大，不利于维护和阅读。

目标：按组件职责拆分为多个文件，同时保持 Dart 库私有（`_` 前缀）规则的约束。

## 拆分方案

在 `src/widgets/glow/` 目录下创建以下 6 个文件，每个公开组件与其私有辅助类同文件：

### 1. `glow_material_level.dart`（~140 行）
**公开导出：**
- `HarmonyGlowMaterialLevel` 枚举
- `HarmonyGlowEffectTuning` 类（含 `copyWith`、`==`、`hashCode`）
- `harmonyGlowLevelForCapability()` 函数
- `HarmonyGlowMaterialLevel` 的 extension（`resolve`、`blurSigma`、`fillOpacity`、`glowOpacity`、`shadowOpacity`、`specularOpacity`、`scatterOpacity`）

### 2. `glow_palette.dart`（~155 行）
**公开导出：**
- `HarmonyGlowPalette` 类及其 factory 构造函数（`light`、`dark`、`fromBrightness`、`fromTheme`）

### 3. `glow_navigation_item.dart`（~35 行）
**公开导出：**
- `HarmonyGlowNavigationItem` 数据模型

### 4. `glow_material.dart`（~475 行）
**公开导出：**
- `HarmonyGlowMaterial` 组件

**私有（仅本文件内可见）：**
- `_HarmonyBackdropScatter` — 散射光幕组件
- `_FilteredBackdrop` — 带颜色叠加的模糊背景
- `_ScatterVeilPainter` — 散射光幕画笔
- `_HarmonyGlowMaterialPainter` — 发光材质核心画笔（光池+镜面高光+边缘描边）

### 5. `immersive_glow_navigation_bar.dart`（~880 行）
**公开导出：**
- `HarmonyImmersiveGlowNavigationBar` 组件

**私有（仅本文件内可见）：**
- `_HarmonyImmersiveGlowNavigationBarState` — 状态管理 + 弹簧物理
- `_NavigationButton` — 导航按钮组件
- `_NavigationGlowPainter` — 导航交互光效画笔

### 6. `glow.dart` — 桶导出文件
```dart
export 'glow_material_level.dart';
export 'glow_palette.dart';
export 'glow_navigation_item.dart';
export 'glow_material.dart';
export 'immersive_glow_navigation_bar.dart';
```

### 需要修改的文件

| 文件 | 修改内容 |
|---|---|
| [harmonyos_ui.dart](../../../packages/harmonyos_ui/lib/harmonyos_ui.dart) | 将 `export 'src/widgets/harmony_immersive_glow.dart';` 替换为 `export 'src/widgets/glow/glow.dart';` |
| [harmony_immersive_glow.dart](../../../packages/harmonyos_ui/lib/src/widgets/harmony_immersive_glow.dart) | **删除** — 所有内容已迁移到新文件 |

### 关键原则

1. **公开 API 不变**：所有公开类、构造函数、方法签名完全保持原样
2. **私有组件不跨文件**：每个 `_` 前缀的类/函数保持与使用它的公开组件同文件
3. **import 最小化**：每个文件只导入实际用到的依赖
4. **文件头部风格统一**：每个文件添加简短的描述注释

## 验证

```bash
cd packages/harmonyos_ui && flutter analyze
```

预期 0 errors、0 warnings。公开 API 完全兼容，所有现有引用无需改动。

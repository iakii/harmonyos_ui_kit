# 修复 HarmonyImmersiveGlowNavigationBar 切换暗色主题时背景不变

## 问题

切换系统主题到暗黑色后，`HarmonyImmersiveGlowNavigationBar` 的背景色没有改变。

## 根因分析

问题出在两层 alpha 覆盖：

1. **`HarmonyGlowPalette.fromTheme()`** 为亮色/暗色设置了不同的 `surfaceTint` alpha（暗色 0.30，亮色 0.18），意图在不同主题下呈现不同的基底填充不透明度。

2. **`_HarmonyGlowMaterialPainter.paint()`** 在绘制表面填充时，用 `fillOpacity`（gentle 模式 = 0.30）**覆盖**了 `surfaceTint` 的 alpha：
   ```dart
   ..color = palette.surfaceTint.withValues(
     alpha: (materialLevel.fillOpacity * effectTuning.surfaceScale).clamp(0, 1),
   );
   ```
   `.withValues(alpha: ...)` 是**替换**而非**乘积**，因此 `fromTheme()` 中设置的不同 alpha 被丢弃，亮/暗两种模式下最终 alpha 都是 0.30。

3. 在 30% 低不透明度下，白色叠加在模糊亮色背景上、深灰 `#1E1E1E` 叠加在模糊暗色背景上，两者的视觉差异微乎其微，用户感知不到背景变化。

## 修复方案

### 修改文件

修改 **2 个文件**，核心思路是让基底的 alpha 由主题决定、不再被 `fillOpacity` 覆盖。

#### 1. `lib/src/widgets/glow/glow_palette.dart` — `fromTheme()` 方法

将 `surfaceTint` 的 alpha 提高到能产生明显背景差异的值：

```dart
// 修改前
surfaceTint: theme.surfaceColor.withValues(alpha: isDark ? 0.30 : 0.18),

// 修改后
surfaceTint: theme.surfaceColor.withValues(alpha: isDark ? 0.55 : 0.25),
```

- 暗色 55%：深灰底板清晰可见，产生明显的暗色表面
- 亮色 25%：白色微透明，保持毛玻璃通透感

#### 2. `lib/src/widgets/glow/glow_material.dart` — `_HarmonyGlowMaterialPainter.paint()` 方法

将基底填充的 alpha 从"替换"改为"使用 surfaceTint 自身的 alpha × surfaceScale"：

```dart
// 修改前（第 451-457 行）
final basePaint = Paint()
  ..color = palette.surfaceTint.withValues(
    alpha: (materialLevel.fillOpacity * effectTuning.surfaceScale).clamp(0, 1),
  );

// 修改后
final basePaint = Paint()
  ..color = palette.surfaceTint.withValues(
    alpha: (palette.surfaceTint.a * effectTuning.surfaceScale).clamp(0.0, 1.0),
  );
```

这样：
- 基底 alpha 由 `HarmonyGlowPalette.fromTheme()` 的主题色 + alpha 决定
- `effectTuning.surfaceScale` 仍可用于微调（默认 1.0 不改变）
- `materialLevel.fillOpacity` 不再干预基底填充（仍用于光泽/高光等效果）

### 润色稿

同时对 `HarmonyGlowPalette.dark()` 预设的 `surfaceTint` 做统一调整，保持一致性：

```dart
// 修改前
surfaceTint: Color(0x4D000000),  // 黑 30%

// 修改后
surfaceTint: Color(0x8C000000),  // 黑 55%
```

## 验证方式

1. 启动应用，确认导航栏在亮色主题下背景呈白色半透明
2. 切换系统主题到暗色，确认导航栏背景变为深色半透明（明显区别于亮色模式）
3. 检查 `effectTuning.surfaceScale` 设为 0 时基底消失、设为 2 时基底加倍
4. 运行 `flutter analyze` 确保无静态分析错误

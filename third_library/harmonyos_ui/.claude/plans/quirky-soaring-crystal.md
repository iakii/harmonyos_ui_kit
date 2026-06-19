# 发光组件关联 HarmonyUI 主题色

## Context

当前实现中，`HarmonyGlowPalette` 的暗色/亮色值是硬编码的，与用户配置的 `HarmonyThemeData`（accentColor、textColor、surfaceColor 等）没有关联。用户希望发光组件自动跟随主题色变化。

## 设计方案

### 核心变更：新增 `HarmonyGlowPalette.fromTheme(HarmonyThemeData)` 工厂

从 `HarmonyThemeData` 中派生所有调色板颜色：

| Palette 字段 | 亮色主题来源 | 暗色主题来源 |
|---|---|---|
| `surfaceTint` | `theme.surfaceColor` (18% 不透明度) | `theme.surfaceColor` (30% 不透明度) |
| `edgeHighlight` | `0xE6FFFFFF` (不变) | `0x1AFFFFFF` (不变) |
| `edgeShadow` | `0x24000000` (不变) | `0x33000000` (不变) |
| `activeColor` | `theme.accentColor.defaultBrushFor(brightness)` 自动选 dark/lighter | 同 |
| `inactiveColor` | `theme.textSecondaryColor` | `theme.textSecondaryColor` |
| `glowColors` | `[accent.light, accent.lighter, accent.lightest]` | `[accent.lighter, accent.light]` |

#### 关键设计选择

- **activeColor 使用 `accentColor.defaultBrushFor(brightness)`**：这个方法已内置亮/暗适配逻辑 — 亮色模式返回较深的 `dark` 变体（保证在白底上可见），暗色模式返回较亮的 `lighter` 变体（保证在黑底上可见）
- **glowColors 使用 accentColor 色阶**：光池颜色与主题色同色系，形成和谐的视觉效果；暗色模式少一个颜色（2 色 vs 3 色）因为暗背景下光池过密显得杂乱
- **edgeHighlight/edgeShadow 保持固定值**：边缘描边模拟物理光照，与主题色无关
- **inactiveColor 使用 `theme.textSecondaryColor`**：确保未选中文字与页面其他次要文字风格一致

### 组件自动检测逻辑简化

当前 `HarmonyGlowMaterial.build()` 和 `NavigationBar build()` 中有双重逻辑：
1. 检测是否为默认 palette → 切换 dark/light 预设
2. 计算 whiteHighlightScale

重构为：
1. 检测是否为默认 palette → 用 `HarmonyGlowPalette.fromTheme(theme)` 替换
2. 计算 whiteHighlightScale（不变）

`HarmonyGlowPalette.light()`/`.dark()` 工厂**保留**，供需要固定预设的用户使用。它们不等于默认 `const HarmonyGlowPalette()` 所以不会被 theme 检测覆盖。

等等，`HarmonyGlowPalette.light()` 返回 `const HarmonyGlowPalette()` = 等于默认。需要修改 `.light()` 工厂，使其不等于默认值。

**解决方案**：给 `HarmonyGlowPalette` 添加一个私有标记字段 `_isPreset`，或更简单的 — 移除 `light()` 和 `dark()`（它们刚添加还没人用），只保留 `fromTheme()` 和 `fromBrightness()`。

实际上，`.light()` 和 `.dark()` 是上一轮刚加的，还没发布。直接修改它们的行为即可。但更好的做法是保留它们作为独立预设，让默认构造函数触发 theme 检测。

**最终方案**：将默认构造的参数全改为可选/nullable，在 build 时如果为 null 则从 theme 填充。但这改动太大。

**最简方案**：widget 的 build() 中检测 `palette == const HarmonyGlowPalette()` → 用 `fromTheme()` 替换。`.light()` 工厂改为返回一个略有不同的 palette（如在某个默认值上做微小偏差），使其不等于默认。但这不优雅。

**最实际方案**：
- 删除 `.light()` 工厂（等于默认，无存在必要）
- `.dark()` 保留为硬编码暗色预设（不等于默认，不会被覆盖）  
- 默认 `const HarmonyGlowPalette()` → widget 自动用 `fromTheme()` 替换
- 用户想固定暗色 → 用 `HarmonyGlowPalette.dark()`
- 用户想自定义 → 用 `HarmonyGlowPalette(surfaceTint: ..., ...)`

实际上再看一下，保留 `.light()` 和 `.dark()` 作为便捷预设是有价值的。用户在不想依赖 theme 上下文时可以用。只是需要确保 `.light()` ≠ 默认值。

简单方案：`.light()` 不返回 `const HarmonyGlowPalette()`，而是显式写一遍默认值。这样 `palette == const HarmonyGlowPalette()` 为 false，theme 检测不会覆盖。

好，就这么定了。

## 实施步骤

### Step 1: 修改 `HarmonyGlowPalette.light()` — 显式展开默认值

```dart
factory HarmonyGlowPalette.light() => const HarmonyGlowPalette(
  surfaceTint: Colors.white,
  edgeHighlight: Color(0xE6FFFFFF),
  edgeShadow: Color(0x24000000),
  activeColor: Color(0xFF1476FF),
  inactiveColor: Color(0xFF15171A),
  glowColors: [Color(0xFF72E3C0), Color(0xFF7C8DF7), Color(0xFFFFC178)],
);
```

### Step 2: 添加 `HarmonyGlowPalette.fromTheme(HarmonyThemeData)` 工厂

在 `dark()` 工厂后插入，使用 theme 的 accentColor、surfaceColor、textSecondaryColor 派生颜色。

### Step 3: 简化 `HarmonyGlowMaterial.build()` 

移除 `isDark` 判断和 hardcoded dark preset，改为：
```dart
final theme = HarmonyTheme.of(context);
final isDark = theme.brightness == Brightness.dark;
final effectivePalette = palette == const HarmonyGlowPalette()
    ? HarmonyGlowPalette.fromTheme(theme)
    : palette;
final whiteHighlightScale = isDark ? 0.65 : 1.0;
```

### Step 4: 简化 `HarmonyImmersiveGlowNavigationBar` build

同上逻辑。

### Step 5: flutter analyze 验证

## 涉及文件

- `third_library/harmonyos_ui/lib/src/widgets/harmony_immersive_glow.dart` — 唯一修改文件

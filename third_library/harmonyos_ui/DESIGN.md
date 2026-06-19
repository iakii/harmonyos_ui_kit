# HarmonyOS UI 设计样式文档

基于 [HarmonyOS NEXT Design System](https://developer.huawei.com/consumer/cn/doc/design-guides/color-0000001776857164) (HDS) 的 Flutter UI 组件库设计规范。


---

## 1. 色彩系统

### 1.1 主题色（Accent Color）

默认主题色为 HarmonyOS 蓝 `#007DFF`，采用七阶色板模型：

| 色阶 | 色值 | 用途 |
|------|--------|------|
| `darkest` | `#003D80` | 极少使用，最深强调 |
| `darker` | `#0050A5` | 深色背景上的强调 |
| `dark` | `#0066CC` | 按下态（pressed） |
| **`normal`** | **`#007DFF`** | **主色，默认填充/选中** |
| `light` | `#3398FF` | 悬停态（hovered） |
| `lighter` | `#66B2FF` | 浅色背景强调 |
| `lightest` | `#99CCFF` | 极浅强调 |

预置色板：`blue`（默认）、`red`（错误/危险）、`green`（成功）、`orange`（警告）。

### 1.2 语义色彩 Token

亮色模式：

| Token | 色值 | 用途 |
|-------|--------|------|
| `pageBackground` | `#F2F2F2` | 页面底色 |
| `surfaceBackground` | `#FFFFFF` | 卡片/表面底色 |
| `overlayBackground` | `#FFFFFF` | 弹窗/弹出层底色 |
| `textPrimary` | `#191919` | 主文字 |
| `textSecondary` | `#999999` | 辅助文字 |
| `textTertiary` | `#BFBFBF` | 占位/禁用文字 |
| `textInverse` | `#FFFFFF` | 反色文字（深色底） |
| `strokePrimary` | `#E5E5E5` | 主边框 |
| `strokeSecondary` | `#F2F2F2` | 次边框 |
| `dividerColor` | `#E5E5E5` | 分割线 |
| `focusRingColor` | `#007DFF` | 焦点环 |
| `controlFillDefault` | `#0A000000` | 控件默认填充 |
| `controlFillHover` | `#14000000` | 控件悬停填充 |
| `controlFillPressed` | `#1F000000` | 控件按下填充 |
| `controlStrokeDefault` | `#D9D9D9` | 控件默认描边 |
| `controlStrokeHover` | `#BFBFBF` | 控件悬停描边 |

暗色模式：

| Token | 色值 | 用途 |
|-------|--------|------|
| `pageBackground` | `#111111` | 页面底色 |
| `surfaceBackground` | `#1E1E1E` | 卡片/表面底色 |
| `overlayBackground` | `#2A2A2A` | 弹窗底色 |
| `textPrimary` | `#FFFFFF` | 主文字 |
| `textSecondary` | `#808080` | 辅助文字 |
| `textTertiary` | `#4D4D4D` | 占位/禁用文字 |
| `textInverse` | `#191919` | 反色文字 |
| `dividerColor` | `#333333` | 分割线 |
| `focusRingColor` | `#3398FF` | 焦点环（暗色下更亮） |

### 1.3 功能色

| 语义 | 色值 | 用途 |
|------|--------|------|
| 信息 Info | `#007DFF` | 提示、链接 |
| 成功 Success | `#00994F` | 成功状态 |
| 警告 Warning | `#FF8000` | 警告状态 |
| 错误 Error | `#FF0000` | 错误/危险操作 |

### 1.4 中性灰阶

从 10（最浅 `#F2F2F2`）到 190（最深 `#0D0D0D`），19 级灰阶，用于精细的层次控制。

---

## 2. 字体系统

### 2.1 字体家族

默认使用系统无衬线字体（优先 HarmonyOS Sans，但库不捆绑字体文件）。

### 2.2 字体阶梯（Type Ramp）

| 样式 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| `headline1` | 32px | Bold (w700) | 1.25 | 大标题 |
| `headline2` | 28px | Bold (w700) | 1.29 | 中标题 |
| `headline3` | 24px | Medium (w500) | 1.33 | 小标题 |
| `title1` | 20px | Medium (w500) | 1.40 | 页面标题 |
| `title2` | 18px | Medium (w500) | 1.44 | 对话框标题 |
| `title3` | 16px | Medium (w500) | 1.50 | 按钮/列表标题 |
| `body` | 14px | Regular (w400) | 1.57 | 正文 |
| `bodySmall` | 12px | Regular (w400) | 1.50 | 辅助正文 |
| `caption` | 11px | Regular (w400) | 1.45 | 说明文字 |
| `overline` | 10px | Medium (w500) | 1.40 | 标签/角标 |

所有样式使用 `TextLeadingDistribution.even`（HDS 默认行高分布）。

---

## 3. 形状 & 圆角

| 组件类型 | 圆角 | 说明 |
|----------|------|------|
| 按钮（Button） | 8px | 填充/描边/文字按钮 |
| 图标按钮 | 8px | 方形小按钮 |
| 输入框 | 8px | 文本输入/密码输入 |
| 搜索框 | 20px | 胶囊形状（pill） |
| 复选框 | 4px | 小圆角方形 |
| 卡片 | 12px | 内容容器 |
| 对话框 | 16px | 弹窗 |
| Toast | 8px | 提示条 |
| BottomSheet | 16px（顶部） | 底部面板 |

---

## 4. 间距系统

基于 8px 网格：

| 间距 | 值 | 用途 |
|------|-----|------|
| `xs` | 4px | 紧凑间距 |
| `sm` | 8px | 组件内部间距 |
| `md` | 12px | 内容间距 |
| `lg` | 16px | 外边距/卡片内边距 |
| `xl` | 20px | 大间距 |
| `xxl` | 24px | 超大间距 |

---

## 5. 组件尺寸规范

### 5.1 按钮

| 属性 | 填充按钮 | 描边按钮 | 文字按钮 | 图标按钮 |
|------|----------|----------|----------|----------|
| 最小高度 | 36px | 36px | 36px | 36px |
| 最小宽度 | 64px | 64px | 48px | 36px |
| 水平内边距 | 20px | 20px | 12px | 6px |
| 垂直内边距 | 8px | 8px | 8px | 6px |
| 图标大小 | 18px | 18px | 18px | 20px |
| 圆角 | 8px | 8px | 8px | 8px |

### 5.2 输入控件

| 组件 | 尺寸 |
|------|------|
| 复选框 | 20×20px，check icon 14px |
| 单选按钮 | 20×20px（外圈），12px（内圆） |
| 开关 | 44×24px（轨道），20px（滑块） |
| 滑块轨道 | 4px 高，thumb 10px 半径 |
| 评分星星 | 24px（默认） |

### 5.3 输入框

| 属性 | 值 |
|------|-----|
| 高度 | 40px（单行） |
| 圆角 | 8px |
| 内边距 | 水平 12px，垂直 10px |
| 图标 | 20px，边距 12px |

### 5.4 导航

| 组件 | 尺寸 |
|------|------|
| TabBar | 48px 高，indicator 3px |
| BottomNavigation | 56px 高 |
| NavigationRail | 72px 宽，item 56px |

### 5.5 其他

| 组件 | 尺寸 |
|------|------|
| 进度条 | 4px 高 |
| 进度环 | 24px（默认），stroke 2.5px |
| 分割线 | 0.5px 厚 |
| AppBar | 56px 高 |

---

## 6. 交互状态

所有交互式组件支持以下状态，通过 `WidgetStateProperty` 驱动：

| 状态 | 触发条件 | 视觉变化 |
|------|----------|----------|
| **idle** | 默认 | 正常颜色 |
| **hovered** | 指针悬停 | 背景/边框变亮（`light` shade），或添加半透明覆盖 |
| **pressed** | 按下 | 背景/边框变暗（`dark` shade），可能缩放（0.9×） |
| **focused** | 键盘焦点 | 焦点环（2px，`focusRingColor`） |
| **disabled** | `onChanged == null` | 灰色替换、不可交互、无反馈 |

### 6.1 按钮颜色映射

| 状态 | 填充按钮 BG | 描边按钮 Border | 文字按钮 BG |
|------|-------------|-----------------|-------------|
| idle | `accent.normal` | `accent.normal` | transparent |
| hovered | `accent.light` | `accent.light` | `accent 5%` |
| pressed | `accent.dark` | `accent.dark` | `accent 10%` |
| disabled | `disabledColor` | `disabledColor` | transparent |

### 6.2 动画时长

| 类型 | 时长 | 曲线 |
|------|------|------|
| 主题切换 | 200ms | `easeInOut` |
| 按钮状态 | 200ms | `easeInOut` |
| 复选框/单选 | 150ms | `easeInOut` |
| 开关 | 200ms | `easeInOut` |
| Toast 出入 | 250ms | `easeOut` |
| 进度条 indeterminate | 2s（循环） | linear |

---

## 7. 阴影 & 海拔

| 层级 | 阴影 | 用途 |
|------|------|------|
| 0 | 无 | 页面背景、输入框 |
| 1 | `0, 1px, 2px, 15%` | 按钮（默认）、卡片（非 elevated） |
| 2 | `0, 2px, 4px, 15%` | 卡片（elevated）、弹窗 |
| 4 | `0, 4px, 8px, 20%` | BottomSheet |

---

## 8. 无障碍

- 所有交互组件均有 `semanticLabel` 属性
- 使用 `Semantics` widget 标记按钮、开关、选中状态
- 焦点环 2px 粗，使用 `focusRingColor` 高可见色
- 键盘导航：Enter/Space 触发按钮
- 颜色对比度符合 WCAG AA 标准

---

## 9. 主题自定义

```dart
HarmonyThemeData(
  // 亮度
  brightness: Brightness.dark,

  // 主题色（可选预置或自定义）
  accentColor: HarmonyColors.blue,  // 默认
  // accentColor: MyColor.toAccentColor(),  // 从任意颜色生成

  // 色彩 Token 覆盖
  colorTokens: HarmonyColorTokens.dark(),

  // 字体自定义
  typography: HarmonyTypography.light().copyWith(
    body: TextStyle(fontSize: 16),
  ),

  // 动画
  animationDuration: Duration(milliseconds: 300),
  animationCurve: Curves.easeOutCubic,

  // 密度
  visualDensity: VisualDensity.compact,
)
```

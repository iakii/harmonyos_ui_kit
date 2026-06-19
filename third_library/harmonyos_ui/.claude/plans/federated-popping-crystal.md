# HarmonyOS UI Flutter 库实现计划

## Context

当前项目是 harmonyos_ui（一个 Flutter 库的初始脚手架），目标是将它打造成一个 HarmonyOS NEXT 风格的完整 UI 组件库，参考 **fluent_ui** 的架构设计。目前只有默认模板代码（`Calculator` 类），需要从零构建。

## 架构设计

仿照 fluent_ui 的分层架构：

```
lib/
├── harmonyos_ui.dart              # 统一导出文件（barrel export）
└── src/
    ├── harmonyos_app.dart         # HarmonyOSApp 根组件
    ├── harmonyos_page_route.dart  # 页面路由（HOS 风格转场）
    ├── icons.dart                 # 图标常量
    ├── utils.dart                 # 工具函数
    ├── styles/                    # 主题系统
    │   ├── color.dart             # AccentColor + 调色板
    │   ├── color_tokens.dart      # HDS 语义色彩 token
    │   ├── theme.dart             # HarmonyTheme / HarmonyThemeData
    │   ├── typography.dart        # HDS 字体阶梯
    │   └── page_transitions.dart  # 页面转场动画
    └── controls/                  # UI 组件
        ├── buttons/               # 按钮（filled/outlined/text/icon）
        ├── inputs/                # 复选框/单选框/开关/滑块/评分
        ├── form_fields/           # 文本输入/搜索/密码
        ├── navigation/            # Tab/底部导航/侧边导航
        ├── surfaces/              # Card/Dialog/Toast/BottomSheet/ListItem/Progress
        ├── layout/                # Page（Scaffold）
        ├── pickers/               # 日期/时间选择器
        └── utils/                 # Divider/InfoLabel/FocusBorder
```

## 核心设计模式

1. **三层样式解析**: `WidgetStyle > ThemeStyle > DefaultStyle`（与 fluent_ui 一致）
2. **WidgetStateProperty**: 基于交互状态（hover/pressed/focused/disabled）的条件样式
3. **InheritedTheme**: 每个组件组有自己的 ThemeData + InheritedTheme
4. **AccentColor**: 七阶色板（darkest→lightest），参考 fluent_ui 的 `AccentColor` 类
5. **HarmonyThemeData**: 工厂构造函数根据 brightness 设置默认值，`copyWith()` / `lerp()` / `merge()`

## 分阶段实施

### Phase 1：基础 + 按钮（核心交付物）

**目标**：验证架构方案，产出可用的主题系统 + 按钮组件。

| 文件 | 说明 |
|------|------|
| `lib/src/styles/color.dart` | `HosAccentColor`（七阶色板）、`HarmonyColors`（blue/red/green/orange/grey）、`ColorExtension` |
| `lib/src/styles/color_tokens.dart` | HDS 语义色彩 token（light/dark），约 20 个核心 token |
| `lib/src/styles/typography.dart` | `HarmonyTypography`，HDS 字体阶梯（headline1~3 / title1~3 / body / caption / overline） |
| `lib/src/styles/theme.dart` | `HarmonyThemeData`（工厂构造 + 亮度驱动默认值）、`HarmonyTheme`（InheritedTheme）、`AnimatedHarmonyTheme` |
| `lib/src/controls/buttons/theme.dart` | `HosButtonStyle`、`HosButtonTheme`、`HosButtonThemeData` |
| `lib/src/controls/buttons/base.dart` | `HosBaseButton`（抽象基类，含 hover/press/focus 状态管理和样式解析） |
| `lib/src/controls/buttons/button.dart` | `HosButton`（主填充按钮，圆角 8px，蓝色主题） |
| `lib/src/controls/buttons/outlined_button.dart` | `HosOutlinedButton`（描边按钮） |
| `lib/src/controls/buttons/text_button.dart` | `HosTextButton`（文字按钮/幽灵按钮） |
| `lib/src/controls/buttons/icon_button.dart` | `HosIconButton`（图标按钮） |
| `lib/src/harmonyos_app.dart` | `HarmonyOSApp`（封装 WidgetsApp，注入主题、滚动行为、本地化） |
| `lib/src/utils.dart` | `debugCheckHasHarmonyTheme()`、`WidgetStateExtension` |
| `lib/harmonyos_ui.dart` | 统一导出文件 |
| `test/` | 更新测试（删除 Calculator 测试，增加主题和按钮测试） |

**HOS 默认主题色**: 蓝色 `#007dFF`

### Phase 2：输入控件

Checkbox、Radio、Switch（Toggle）、Slider、RatingBar

### Phase 3：表单输入

TextInput、SearchBox、PasswordInput、TextFormInput

### Phase 4：导航组件

TabBar、BottomNavigation、NavigationRail

### Phase 5：表面 + 反馈组件

Card、Dialog、Toast、BottomSheet、ListItem、ProgressBar/ProgressRing、Loading、EmptyState/ErrorState

### Phase 6：布局 + 选择器 + 打磨

HosPage（Scaffold）、DatePicker、TimePicker、Divider、InfoLabel、FocusBorder

## 验证方法

1. `flutter analyze` — 零错误
2. `flutter test` — 所有测试通过
3. 编写 example 程序（后续可创建 `example/` 目录），验证整套主题和按钮在实际 App 中的效果

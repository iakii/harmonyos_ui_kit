# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Flutter/Dart **库**(package)，提供 HarmonyOS NEXT 风格的 UI 组件库。

## 常用命令

```bash
# 安装依赖
flutter pub get

# 静态分析 / lint 检查
flutter analyze

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/harmonyos_ui_test.dart
```

## 代码架构

仿照 `fluent_ui` 的分层架构设计：

```
lib/
├── harmonyos_ui.dart              # 统一导出（barrel export）
└── src/
    ├── harmonyos_app.dart         # HarmonyOSApp 根组件（基于 MaterialApp）
    ├── harmonyos_page_route.dart  # 页面路由
    ├── utils.dart                 # WidgetStateExtension 等工具
    ├── styles/                    # 主题系统
    │   ├── color.dart             # HosAccentColor（七阶色板）+ HarmonyColors
    │   ├── color_tokens.dart      # HDS 语义色彩 token（light/dark）
    │   ├── theme.dart             # HarmonyThemeData / HarmonyTheme / AnimatedHarmonyTheme
    │   ├── typography.dart        # 字体阶梯（headline1~3 / title1~3 / body / caption / overline）
    │   └── page_transitions.dart  # 页面转场动画
    └── controls/                  # UI 组件
        ├── buttons/               # button / outlined_button / text_button / icon_button + theme
        ├── inputs/                # checkbox / radio / toggle_switch / slider / rating_bar
        ├── form_fields/           # text_input / search_box / password_input / text_form_input
        ├── navigation/            # tab_bar / bottom_navigation / navigation_rail
        ├── surfaces/              # card / dialog / toast / bottom_sheet / list_item / progress / loading / empty_state
        ├── layout/                # page (HosPage scaffold)
        ├── pickers/               # date_picker / time_picker
        └── utils/                 # divider / info_label / focus_border
```

## 核心设计模式

1. **三层样式解析**: `WidgetStyle > ThemeStyle > DefaultStyle` — 组件属性按此优先级解析
2. **WidgetStateProperty**: 基于交互状态（hover/pressed/focused/disabled）的条件样式
3. **HosBaseButton**: 所有按钮继承的抽象基类，管理 hover/press/focus 状态和样式解析
4. **HosAccentColor**: 七阶色板（darkest→lightest），默认蓝色 `#007dFF`
5. **HarmonyThemeData**: 工厂构造函数根据 brightness 设置默认值，支持 `copyWith()` / `merge()` / `lerp()`

## 已实现组件

- **主题系统**: `HarmonyThemeData`、`HarmonyTheme`、`AnimatedHarmonyTheme`、`HarmonyColorTokens`、`HarmonyTypography`
- **按钮**: `HosButton`（填充/主按钮）、`HosOutlinedButton`（描边）、`HosTextButton`（文字/幽灵）、`HosIconButton`（图标按钮）
- **输入控件**: `HosCheckbox`（复选框）、`HosRadio`（单选按钮）、`HosSwitch`（开关）、`HosSlider`（滑块）、`HosRatingBar`（星星评分）
- **表单输入**: `HosTextInput`（文本输入）、`HosSearchBox`（搜索框）、`HosPasswordInput`（密码输入）、`HosTextFormInput`（表单域）
- **布局**: `HosPage`（页面脚手架，带 AppBar+SafeArea）
- **选择器**: `showHosDatePicker`（日期选择）、`showHosTimePicker`（时间选择）
- **导航**: `HosTabBar`（选项卡）、`HosBottomNavigation`（底部导航）、`HosNavigationRail`（侧边导航）
- **表面**: `HosCard`（卡片）、`showHosDialog`（对话框）、`showHosToast`（提示）、`showHosBottomSheet`（底部弹出）、`HosListItem`（列表项）、`HosProgressBar`/`HosProgressRing`（进度条/环）、`HosLoading`（加载）`HosEmptyState`/`HosErrorState`（空态/错误态）
- **工具**: `HosDivider`（分割线）、`HosInfoLabel`（信息标签+tooltip）、`HosFocusBorder`（焦点指示环）
- **应用壳**: `HarmonyOSApp` + `HarmonyOSApp.router()`

## 环境要求

- Flutter SDK `>=1.17.0`，Dart SDK `^3.9.2`
- 这是一个库 package，不应包含 `pubspec.lock`（已在 `.gitignore` 中忽略）

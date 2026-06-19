# harmonyos_ui

HarmonyOS NEXT 风格 UI 组件库 for Flutter。

仿照 `fluent_ui` 架构设计，提供完整的 HarmonyOS Design System (HDS) 风格组件，支持亮色/暗色模式、丰富的交互状态（hover/pressed/focused/disabled）和无障碍语义标签。

## 快速开始

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  harmonyos_ui:
    path: packages/harmonyos_ui
```

```dart
import 'package:harmonyos_ui/harmonyos_ui.dart';

void main() => runApp(HarmonyOSApp(
  title: 'My App',
  home: MyHomePage(),
  theme: HarmonyThemeData.light(),
  darkTheme: HarmonyThemeData.dark(),
));
```

## 组件总览

### 主题系统

| 类/组件 | 说明 |
|----------|------|
| `HarmonyThemeData` | 主题数据配置（工厂构造，`copyWith`/`merge`/`lerp`） |
| `HarmonyTheme` | InheritedTheme，向下传播主题 |
| `AnimatedHarmonyTheme` | 平滑过渡的主题动画 |
| `HarmonyColorTokens` | HDS 语义色彩 token（light/dark） |
| `HarmonyTypography` | HDS 字体阶梯（headline1~3 / title1~3 / body / caption / overline） |
| `HosAccentColor` | 七阶色板（darkest→lightest），默认蓝 `#007DFF` |
| `HarmonyColors` | 预置色板：blue / red / green / orange / grey |

```dart
// 自定义主题
HarmonyThemeData(
  brightness: Brightness.dark,
  accentColor: HarmonyColors.red,
  typography: HarmonyTypography.light().copyWith(
    body: TextStyle(fontSize: 16),
  ),
)
```

### 按钮

| 组件 | 说明 |
|------|------|
| `HosButton` | 主填充按钮 |
| `HosOutlinedButton` | 描边按钮（次要操作） |
| `HosTextButton` | 文字按钮（幽灵按钮） |
| `HosIconButton` | 图标按钮 |

```dart
HosButton(onPressed: () {}, child: Text('确认'))
HosOutlinedButton(onPressed: () {}, child: Text('取消'))
HosTextButton(onPressed: () {}, child: Text('了解更多'))
HosIconButton(onPressed: () {}, child: Icon(Icons.settings))
```

### 输入控件

| 组件 | 说明 |
|------|------|
| `HosCheckbox` | 复选框，带动画缩放 |
| `HosRadio` | 单选按钮 |
| `HosSwitch` | 开关切换 |
| `HosSlider` | 滑块（CustomPaint 绘制） |
| `HosRatingBar` | 星星评分，支持半星 |

```dart
HosCheckbox(checked: isChecked, onChanged: (v) => setState(() => isChecked = v))
HosRadio(selected: _value == 1, onChanged: () => setState(() => _value = 1))
HosSwitch(checked: isOn, onChanged: (v) => setState(() => isOn = v))
HosSlider(value: 0.5, min: 0, max: 1, onChanged: (v) => setState(() => _val = v))
HosRatingBar(rating: 3.5, maxRating: 5, onChanged: (v) => setState(() => rating = v))
```

### 表单输入

| 组件 | 说明 |
|------|------|
| `HosTextInput` | 文本输入框（前缀/后缀图标、清除按钮、错误/帮助文本） |
| `HosSearchBox` | 搜索框（胶囊形状） |
| `HosPasswordInput` | 密码输入（可见性切换） |
| `HosTextFormInput` | 表单域（集成 Form/FormField 验证） |

```dart
HosTextInput(placeholder: 'Enter name', onChanged: (v) => print(v))
HosSearchBox(placeholder: 'Search...', onSubmitted: (v) => search(v))
HosPasswordInput(placeholder: 'Password')
HosTextFormInput(placeholder: 'Email', validator: (v) => v?.contains('@') == true ? null : 'Invalid')
```

### 导航

| 组件 | 说明 |
|------|------|
| `HosTabBar` | 选项卡（animated underline indicator） |
| `HosBottomNavigation` | 底部导航栏 |
| `HosNavigationRail` | 侧边导航栏（适合平板/桌面） |

```dart
HosTabBar(tabs: ['Tab A', 'Tab B'], selectedIndex: 0, onChanged: (i) => ...)
HosBottomNavigation(
  items: [HosBottomNavItem(icon: Icons.home, label: 'Home'), ...],
  selectedIndex: 0, onChanged: (i) => ...,
)
HosNavigationRail(
  items: [HosNavRailItem(icon: Icons.home, label: 'Home'), ...],
  selectedIndex: 0, onChanged: (i) => ...,
)
```

### 表面 & 反馈

| 组件 | 说明 |
|------|------|
| `HosCard` | 圆角卡片（可选阴影） |
| `showHosDialog` | 弹窗对话框 |
| `showHosToast` | 底部 Toast 提示（自动消失） |
| `showHosBottomSheet` | 底部弹出面板 |
| `HosListItem` | 列表项（leading / title / subtitle / trailing） |
| `HosProgressBar` | 线性进度条（determinate / indeterminate） |
| `HosProgressRing` | 环形进度指示器 |
| `HosLoading` | 加载指示器（inline / overlay） |
| `HosEmptyState` | 空状态占位 |
| `HosErrorState` | 错误状态占位（含 retry） |

```dart
HosCard(child: Text('Content'))
final result = await showHosDialog(context: context, title: 'Confirm', content: 'Sure?')
showHosToast(context: context, message: 'Saved!')
showHosBottomSheet(context: context, builder: (_) => Text('Content'))
HosListItem(title: 'John', subtitle: 'Online', onTap: () {})
HosProgressBar(value: 0.6)
HosProgressRing()
HosLoading.show(context)  // returns dismiss callback
HosEmptyState(icon: Icons.inbox, title: 'Empty', message: 'Nothing here')
HosErrorState(message: 'Failed to load', onRetry: () => reload())
```

### 布局 & 工具

| 组件 | 说明 |
|------|------|
| `HosPage` | 页面脚手架（AppBar + SafeArea + 背景色） |
| `showHosDatePicker` | 日期选择器 |
| `showHosTimePicker` | 时间选择器 |
| `HosDivider` | 分割线（支持居中 label） |
| `HosInfoLabel` | 设置项标签（info 图标 + tooltip） |
| `HosFocusBorder` | 焦点指示环（键盘导航反馈） |

```dart
HosPage(title: 'Settings', body: ListView(...))
final date = await showHosDatePicker(context: context, initialDate: ..., firstDate: ..., lastDate: ...)
final time = await showHosTimePicker(context: context, initialTime: TimeOfDay.now())
HosDivider(label: 'OR')
HosInfoLabel(label: 'Dark mode', info: 'Enable dark theme', child: HosSwitch(...))
HosFocusBorder(child: HosButton(...))
```

## 架构

仿照 `fluent_ui` 分层架构：

```
lib/
├── harmonyos_ui.dart              # 统一导出
└── src/
    ├── harmonyos_app.dart         # HarmonyOSApp 根组件
    ├── styles/                    # 主题系统
    │   ├── color.dart             # HosAccentColor + HarmonyColors
    │   ├── color_tokens.dart      # HDS 语义色彩 token
    │   ├── theme.dart             # HarmonyThemeData / HarmonyTheme
    │   └── typography.dart        # HDS 字体阶梯
    └── controls/
        ├── buttons/               # 按钮组
        ├── inputs/                # 复选框/单选框/开关/滑块/评分
        ├── form_fields/           # 文本输入/搜索/密码/表单域
        ├── navigation/            # Tab/底部导航/侧边导航
        ├── surfaces/              # Card/Dialog/Toast/BottomSheet/ListItem/Progress/Loading/EmptyState
        ├── layout/                # HosPage
        ├── pickers/               # 日期/时间选择器
        └── utils/                 # Divider/InfoLabel/FocusBorder
```

### 核心设计

- **三层样式解析**: `WidgetStyle → ThemeStyle → DefaultStyle`
- **WidgetStateProperty**: 基于交互状态的条件样式
- **HosAccentColor**: 七阶色板，支持 `lerp` / `copyWith`
- **HarmonyThemeData**: `factory` 构造 → `raw()` 内部 → `copyWith()` / `merge()` / `lerp()`

## 环境要求

- Flutter SDK `>=1.17.0`
- Dart SDK `^3.9.2`

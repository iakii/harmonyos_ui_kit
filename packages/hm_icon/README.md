# hm_icon

HarmonyOS NEXT Symbol Icons for Flutter.

基于 HMSymbolVF 可变字体，提供 4600+ HarmonyOS NEXT 风格图标。 [预览](https://erbws.github.io/hm-symbol/)

## 安装

```yaml
# pubspec.yaml
dependencies:
  hm_icon:
    path: packages/hm_icon
```

## 使用

```dart
import 'package:hm_icon/hm_icon.dart';

// 基础用法
Icon(HMIcons.wifi);
Icon(HMIcons.heart_fill);
Icon(HMIcons.star_fill);
Icon(HMIcons.trash);

// 自定义样式
Icon(
  HMIcons.wifi,
  size: 24,
  color: Colors.blue,
);
```

## 图标命名规则

图标名称采用 camelCase 命名，遵循以下规则：

| 后缀 | 含义 |
|------|------|
| `*Fill` | 填充样式 |
| `*Slash` | 斜线/禁用 |
| `*Circle` | 圆形变体 |
| `*CircleFill` | 圆形填充 |

示例：
- `heart` / `heartFill` / `heartSlash`
- `checkmarkCircle` / `checkmarkCircleFill`
- `starFill`

## 图标列表

全部图标列表请查看 `lib/src/hm_icon_data.dart`，共 4600+ 个图标。

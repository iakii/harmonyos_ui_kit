# 计划：HarmonyTheme 支持自定义字体

## 背景

当前 `HarmonyTheme` 没有提供便捷的自定义字体设置入口。虽然 `HarmonyTypography` 已有 `apply(fontFamily: ...)` 方法，但用户必须手动构造 typography：

```dart
HarmonyThemeData(
  typography: HarmonyTypography.light().apply(fontFamily: "MyFont"),
)
```

预期体验：

```dart
HarmonyThemeData(fontFamily: "MyFont")
```

此外，`app_bar.dart:174` 硬编码了 `fontFamily: "HarmonyOs Sans SC"`，会覆盖主题级字体设置。

## 修改文件

| 文件 | 修改内容 |
|------|----------|
| `lib/src/styles/typography.dart` | 添加 `fontFamilyFallback` 字段，更新 `apply`/`copyWith`/`merge`/`lerp` |
| `lib/src/styles/theme.dart` | `HarmonyThemeData` 添加 `fontFamily` + `fontFamilyFallback` 字段 |
| `lib/src/controls/navigation/app_bar.dart` | 移除硬编码的 `fontFamily: "HarmonyOs Sans SC"` |
| `test/harmonyos_ui_test.dart` | 添加测试用例 |

## 详细设计

### 1. `HarmonyTypography`（typography.dart）

**新增字段**：`final List<String>? fontFamilyFallback`

**修改点**：

- **构造函数**：添加可选参数 `this.fontFamilyFallback`
- **`apply()`**：添加 `List<String>? fontFamilyFallback` 参数。若未传，回退到 `this.fontFamilyFallback`。将它传入每个 `TextStyle.apply()` 调用。结果实例也保存该值。
- **`copyWith()`**：添加 `List<String>? fontFamilyFallback` 参数
- **`merge()`**：添加 `fontFamilyFallback: other.fontFamilyFallback ?? this.fontFamilyFallback`
- **`lerp()`**：离散值，`t < 0.5` 取 a、否则取 b
- **`debugFillProperties()`**：添加诊断输出

### 2. `HarmonyThemeData`（theme.dart）

**新增字段**：
- `final String? fontFamily`
- `final List<String>? fontFamilyFallback`

**修改点**：

- **工厂构造函数**：添加 `String? fontFamily` 和 `List<String>? fontFamilyFallback` 参数。在 resolved typography 之后，若 fontFamily 或 fontFamilyFallback 非空，调用 `resolvedTypography.apply(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback)` 覆盖。

  **优先级规则**：当同时提供 `typography` 和 `fontFamily` 时，fontFamily 通过 `apply()` 叠加到 typography 之上——主题级 fontFamily 总是胜出。这是合理的行为。

- **`raw()` 构造函数**：添加 `required this.fontFamily` 和 `required this.fontFamilyFallback`
- **`copyWith()`**：添加对应参数和传播
- **`merge()`**：添加覆盖逻辑（与现有模式一致）
- **`lerp()`**：离散值，`t < 0.5` 取 a、否则取 b（6 个分支都要加）
- **`debugFillProperties()`**：添加诊断输出

### 3. `app_bar.dart`

移除第 174 行的 `fontFamily: "HarmonyOs Sans SC",`，让 AppBar 标题跟随主题字体。

### 4. 测试

添加以下测试用例：
1. `HarmonyThemeData(fontFamily: "MyFont")` — 验证 typography 所有 10 级样式都带上了 fontFamily
2. `HarmonyThemeData(fontFamilyFallback: ["Fallback"])` — 验证 fallback 列表传播
3. `HarmonyThemeData(typography: custom, fontFamily: "Overlay")` — 验证叠加行为
4. `HarmonyThemeData.copyWith(fontFamily: "NewFont")` — 验证 copyWith
5. `HarmonyThemeData.merge()` — 验证 merge 语义
6. `HarmonyTypography.apply(fontFamilyFallback: [...])` — 验证 apply 扩展

## 向后兼容性

- 新字段全部可选，默认 `null`——现有代码不受影响
- `HarmonyThemeData.raw()` 增加 required 参数——此为内部 API，不影响正常用户
- `HarmonyTypography.apply()` 新增参数在末尾——不影响现有调用

## 验证方式

```bash
cd packages/harmonyos_ui
flutter analyze   # 静态分析通过
flutter test      # 所有测试通过
```

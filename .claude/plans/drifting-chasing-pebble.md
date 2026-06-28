# 调整设置面板卡片布局

## 背景

用户要求调整 `setting_panel.dart` 中配置源卡片的内部间距：卡片上下左右间距统一为 12，头像圆角 12 在左侧，标题和 HosRadio 选中组件在右侧。

## 改动

**文件**: `lib/presentation/pages/js_gallery/widgets/setting_panel.dart`

**变更**: 第 76 行的 `.padding(vertical: 8)` → `.padding(all: 12)`

## 验证

- 运行 `flutter analyze` 确认无语法错误
- 如有运行环境，打开设置页面确认卡片间距视觉效果

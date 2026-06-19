/// [HarmonyImmersiveGlowNavigationBar] 使用的导航项数据模型。
library;

import 'package:flutter/material.dart';

// =============================================================================
// 导航项数据模型
// =============================================================================

/// [HarmonyImmersiveGlowNavigationBar] 中的单个导航项。
///
/// 每个项包含：
/// - [icon]：默认图标（必填）
/// - [activeIcon]：选中态图标（可选，不填则复用 [icon]）
/// - [label]：文字标签（必填）
/// - [tooltip]：无障碍提示（可选，默认取 [label]）
@immutable
class HarmonyGlowNavigationItem {
  const HarmonyGlowNavigationItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.tooltip,
  });

  /// 默认状态图标。
  final Widget icon;

  /// 选中状态图标，为 null 时复用 [icon]。
  final Widget? activeIcon;

  /// 文字标签。
  final String label;

  /// 无障碍 tooltip 文本。
  final String? tooltip;
}

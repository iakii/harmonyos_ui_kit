/// [HarmonyGlowMaterial] 和 [HarmonyImmersiveGlowNavigationBar] 使用的颜色配方。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../styles/theme.dart';

// =============================================================================
// 调色板 — 发光材质的颜色配方
// =============================================================================

/// [HarmonyGlowMaterial] 和 [HarmonyImmersiveGlowNavigationBar] 使用的颜色配方。
///
/// 包含六组颜色定义：
/// - [surfaceTint]：半透明基色
/// - [edgeHighlight]：上/外边缘亮色描边
/// - [edgeShadow]：下边缘暗色 + 投影色
/// - [activeColor]：选中态图标/文字颜色
/// - [inactiveColor]：未选中态图标/文字颜色
/// - [glowColors]：背景光池的渐变颜色列表
@immutable
class HarmonyGlowPalette {
  const HarmonyGlowPalette({
    this.surfaceTint = Colors.white,
    this.edgeHighlight = const Color(0xE6FFFFFF),
    this.edgeShadow = const Color(0x24000000),
    this.activeColor = const Color(0xFF1476FF),
    this.inactiveColor = const Color(0xFF15171A),
    this.glowColors = const <Color>[
      Color(0xFF72E3C0),
      Color(0xFF7C8DF7),
      Color(0xFFFFC178),
    ],
  });

  /// 亮色主题预设（固定值，不受当前主题影响）。
  ///
  /// 白色基底 + 亮色描边 + 彩色光池（青绿/蓝紫/暖橙）。
  /// 如需自动跟随 HarmonyUI 主题色，使用默认构造 [HarmonyGlowPalette]。
  factory HarmonyGlowPalette.light() => const HarmonyGlowPalette(
    surfaceTint: Colors.white,
    edgeHighlight: Color(0xE6FFFFFF),
    edgeShadow: Color(0x24000000),
    activeColor: Color(0xFF1476FF),
    inactiveColor: Color(0xFF15171A),
    glowColors: <Color>[
      Color(0xFF72E3C0),
      Color(0xFF7C8DF7),
      Color(0xFFFFC178),
    ],
  );

  /// 暗色主题预设。
  ///
  /// 深色半透明基底 + 微弱亮边 + 靛蓝/紫色光池。
  /// 选中色为亮蓝 `0xFF4DA6FF`，未选中色为浅灰 `0xFFCCCCCC`。
  factory HarmonyGlowPalette.dark() => const HarmonyGlowPalette(
    surfaceTint: Color(0x8C000000),
    edgeHighlight: Color(0x1AFFFFFF),
    edgeShadow: Color(0x33000000),
    activeColor: Color(0xFF4DA6FF),
    inactiveColor: Color(0xFFCCCCCC),
    glowColors: <Color>[Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  /// 根据 [brightness] 返回对应的调色板预设。
  ///
  /// [Brightness.light] → [HarmonyGlowPalette.light]
  /// [Brightness.dark]  → [HarmonyGlowPalette.dark]
  factory HarmonyGlowPalette.fromBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return HarmonyGlowPalette.light();
      case Brightness.dark:
        return HarmonyGlowPalette.dark();
    }
  }

  /// 从 [HarmonyThemeData] 派生调色板，自动跟随主题色变化。
  ///
  /// 各颜色映射关系：
  /// - [surfaceTint]：主题 [HarmonyThemeData.surfaceColor]，亮色 25% / 暗色 55% 不透明度
  /// - [activeColor]：`accentColor.defaultBrushFor(brightness)`（自动亮/暗适配）
  /// - [inactiveColor]：主题 [HarmonyThemeData.textSecondaryColor]
  /// - [glowColors]：accentColor 的 `light`/`lighter`/`lightest` 色阶
  /// - [edgeHighlight]/[edgeShadow]：固定值（模拟物理光照，不随主题变化）
  ///
  /// 当使用默认构造 [HarmonyGlowPalette]（未传入任何参数）时，
  /// [HarmonyGlowMaterial] 和 [HarmonyImmersiveGlowNavigationBar] 会自动
  /// 调用此工厂从当前 [HarmonyTheme] 派生颜色，实现与主题色的自动关联。
  factory HarmonyGlowPalette.fromTheme(HarmonyThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.accentColor;
    return HarmonyGlowPalette(
      surfaceTint: theme.surfaceColor.withValues(alpha: isDark ? 0.6 : 0.25),
      edgeHighlight: isDark ? const Color(0x1AFFFFFF) : const Color(0xE6FFFFFF),
      edgeShadow: isDark ? const Color(0x33000000) : const Color(0x24000000),
      activeColor: accent.defaultBrushFor(theme.brightness),
      inactiveColor: theme.textSecondaryColor,
      glowColors: isDark
          ? <Color>[accent.lighter, accent.light]
          : <Color>[accent.light, accent.lighter, accent.lightest],
    );
  }

  /// 材质面板的半透明基底色。
  ///
  /// 默认白色，可根据背景色调调整为深色半透明（如暗色模式下用
  /// `Colors.black.withValues(alpha: 0.3)`）。
  final Color surfaceTint;

  /// 上边缘和外边缘的亮色描边。
  ///
  /// 模拟光线从上方照射时面板顶部的高亮反射。
  final Color edgeHighlight;

  /// 下边缘的暗色描边 + 投影色。
  ///
  /// 与 [edgeHighlight] 配合形成上亮下暗的立体边缘。
  final Color edgeShadow;

  /// 选中图标和文字的颜色。
  final Color activeColor;

  /// 未选中图标和文字的颜色。
  final Color inactiveColor;

  /// 混合在材质背后的光池颜色列表。
  ///
  /// 默认三色：青绿 → 蓝紫 → 暖橙，分别以不同相位绕中心旋转。
  final List<Color> glowColors;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HarmonyGlowPalette &&
            other.surfaceTint == surfaceTint &&
            other.edgeHighlight == edgeHighlight &&
            other.edgeShadow == edgeShadow &&
            other.activeColor == activeColor &&
            other.inactiveColor == inactiveColor &&
            listEquals(other.glowColors, glowColors);
  }

  @override
  int get hashCode => Object.hash(
    surfaceTint,
    edgeHighlight,
    edgeShadow,
    activeColor,
    inactiveColor,
    Object.hashAll(glowColors),
  );
}

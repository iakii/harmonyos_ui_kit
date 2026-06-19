/// 发光材质的材质等级、效果微调参数和运行时解析逻辑。
///
/// 命名遵循 HarmonyOS Design System（HDS）公开的材质术语。实现是 Flutter
/// 原生的，不绑定 HarmonyOS 系统材质 API。
library;

import 'package:flutter/material.dart';

// =============================================================================
// 材质等级枚举 — 控制发光材质的渲染质量/性能档位
// =============================================================================

/// 发光材质的近似材质等级。
///
/// 命名遵循 HarmonyOS Design System（HDS）公开的材质术语。实现是 Flutter
/// 原生的，不绑定 HarmonyOS 系统材质 API。
///
/// 四个等级从高到低：
/// - [adaptive]：根据上下文自动选择（禁用动画时降级为 [smooth]）
/// - [exquisite]：精致 — 最强效果，模糊半径 34px，适合高端设备
/// - [gentle]：柔和 — 中等效果，模糊半径 22px，默认等级
/// - [smooth]：流畅 — 轻量效果，模糊半径 8px，适合低端设备/省电模式
enum HarmonyGlowMaterialLevel { adaptive, exquisite, gentle, smooth }

// =============================================================================
// 效果微调 — 在不改变材质等级的前提下，独立缩放各视觉维度
// =============================================================================

/// 用于在不改变材质等级的情况下微调模拟材质的各项乘数。
///
/// 所有乘数默认为 1.0（不调整），设为 0 则完全禁用该效果维度。
///
/// 七个可调维度：
/// - [blurScale]：背景模糊强度
/// - [surfaceScale]：表面填充不透明度
/// - [glowScale]：光池亮度
/// - [shadowScale]：投影深度
/// - [specularScale]：镜面高光强度
/// - [elasticScale]：弹性形变幅度
/// - [scatterScale]：散射光幕强度
@immutable
class HarmonyGlowEffectTuning {
  const HarmonyGlowEffectTuning({
    this.blurScale = 1,
    this.surfaceScale = 1,
    this.glowScale = 1,
    this.shadowScale = 1,
    this.specularScale = 1,
    this.elasticScale = 1,
    this.scatterScale = 0,
  }) : assert(blurScale >= 0),
       assert(surfaceScale >= 0),
       assert(glowScale >= 0),
       assert(shadowScale >= 0),
       assert(specularScale >= 0),
       assert(elasticScale >= 0),
       assert(scatterScale >= 0);

  /// 背景模糊强度乘数
  final double blurScale;

  /// 表面填充不透明度乘数
  final double surfaceScale;

  /// 光池亮度乘数
  final double glowScale;

  /// 投影深度乘数
  final double shadowScale;

  /// 镜面高光强度乘数
  final double specularScale;

  /// 弹性形变幅度乘数
  final double elasticScale;

  /// 散射光幕强度乘数（默认 0，即关闭散射层）
  final double scatterScale;

  /// 创建当前配置的副本，仅覆盖指定字段。
  HarmonyGlowEffectTuning copyWith({
    double? blurScale,
    double? surfaceScale,
    double? glowScale,
    double? shadowScale,
    double? specularScale,
    double? elasticScale,
    double? scatterScale,
  }) {
    return HarmonyGlowEffectTuning(
      blurScale: blurScale ?? this.blurScale,
      surfaceScale: surfaceScale ?? this.surfaceScale,
      glowScale: glowScale ?? this.glowScale,
      shadowScale: shadowScale ?? this.shadowScale,
      specularScale: specularScale ?? this.specularScale,
      elasticScale: elasticScale ?? this.elasticScale,
      scatterScale: scatterScale ?? this.scatterScale,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HarmonyGlowEffectTuning &&
            other.blurScale == blurScale &&
            other.surfaceScale == surfaceScale &&
            other.glowScale == glowScale &&
            other.shadowScale == shadowScale &&
            other.specularScale == specularScale &&
            other.elasticScale == elasticScale &&
            other.scatterScale == scatterScale;
  }

  @override
  int get hashCode => Object.hash(
    blurScale,
    surfaceScale,
    glowScale,
    shadowScale,
    specularScale,
    elasticScale,
    scatterScale,
  );
}

// =============================================================================
// 能力检测 → 材质等级映射
// =============================================================================

/// 根据宿主端能力检测结果选择合适的材质等级。
///
/// HarmonyOS ArkUI 暴露了 [getSystemMaterialTypes()] API。作为可移植的
/// Flutter 包无法直接查询该 API，因此应用可将检测结果传入此函数，再将
/// 返回的等级喂给 [HarmonyGlowMaterial.materialLevel] 或
/// [HarmonyImmersiveGlowNavigationBar.materialLevel]。
///
/// 参数：
/// - [supportsImmersiveMaterial]：宿主是否支持沉浸式材质。
/// - [preferExquisite]：支持时是否偏好精致等级（默认 true，false 则回退到柔和）。
HarmonyGlowMaterialLevel harmonyGlowLevelForCapability({
  required bool supportsImmersiveMaterial,
  bool preferExquisite = true,
}) {
  // 不支持沉浸式材质 → 流畅（最轻量）
  if (!supportsImmersiveMaterial) {
    return HarmonyGlowMaterialLevel.smooth;
  }
  // 支持时按偏好选择精致或柔和
  return preferExquisite
      ? HarmonyGlowMaterialLevel.exquisite
      : HarmonyGlowMaterialLevel.gentle;
}

// =============================================================================
// 材质等级扩展 — 运行时解析 + 各等级物理参数
// =============================================================================

extension HarmonyGlowMaterialLevelExtension on HarmonyGlowMaterialLevel {
  /// 在给定 [BuildContext] 中解析自适应等级。
  ///
  /// 非 [adaptive] 等级直接返回自身；
  /// [adaptive] 在动画被禁用时降级为 [smooth]，否则使用 [gentle]。
  HarmonyGlowMaterialLevel resolve(BuildContext context) {
    if (this != HarmonyGlowMaterialLevel.adaptive) {
      return this;
    }

    return MediaQuery.disableAnimationsOf(context)
        ? HarmonyGlowMaterialLevel.smooth
        : HarmonyGlowMaterialLevel.gentle;
  }

  /// 背景模糊 sigma 值（高斯模糊半径）。
  ///
  /// | 等级 | 值 | 说明 |
  /// |------|-----|------|
  /// | exquisite | 34 | 大范围柔和模糊 |
  /// | adaptive/gentle | 22 | 中等模糊 |
  /// | smooth | 8 | 轻模糊，性能优先 |
  double get blurSigma {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return 22;
      case HarmonyGlowMaterialLevel.exquisite:
        return 34;
      case HarmonyGlowMaterialLevel.smooth:
        return 8;
    }
  }

  /// 表面填充层的不透明度。
  ///
  /// 注意：smooth 等级填充最重（.58），因为它的模糊效果最弱，
  /// 需要更厚实的表面来维持毛玻璃观感。
  double get fillOpacity {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return .3;
      case HarmonyGlowMaterialLevel.exquisite:
        return .13;
      case HarmonyGlowMaterialLevel.smooth:
        return .58;
    }
  }

  /// 光池（彩色径向渐变）的不透明度。
  double get glowOpacity {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return .28;
      case HarmonyGlowMaterialLevel.exquisite:
        return .34;
      case HarmonyGlowMaterialLevel.smooth:
        return .05;
    }
  }

  /// 底部投影的不透明度。
  double get shadowOpacity {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return .16;
      case HarmonyGlowMaterialLevel.exquisite:
        return .24;
      case HarmonyGlowMaterialLevel.smooth:
        return .08;
    }
  }

  /// 镜面高光扫描的不透明度。
  double get specularOpacity {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return .38;
      case HarmonyGlowMaterialLevel.exquisite:
        return .48;
      case HarmonyGlowMaterialLevel.smooth:
        return .12;
    }
  }

  /// 散射光幕的不透明度。
  ///
  /// gentle/adaptive 散射较强（.9），营造柔和光线散射感；
  /// exquisite 散射适中（.48），更强调光池和镜面效果。
  double get scatterOpacity {
    switch (this) {
      case HarmonyGlowMaterialLevel.adaptive:
      case HarmonyGlowMaterialLevel.gentle:
        return .9;
      case HarmonyGlowMaterialLevel.exquisite:
        return .48;
      case HarmonyGlowMaterialLevel.smooth:
        return .08;
    }
  }
}

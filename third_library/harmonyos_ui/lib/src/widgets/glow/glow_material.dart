/// 可复用的半透明材质面板，模拟 HDS 风格的沉浸式光效。
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../styles/theme.dart';
import 'glow_material_level.dart';
import 'glow_palette.dart';

// =============================================================================
// HarmonyGlowMaterial — 核心发光材质组件
// =============================================================================

/// 可复用的半透明材质面板，模拟 HDS 风格的沉浸式光效。
///
/// ## 视觉效果
///
/// 放置在彩色或图片内容之上。组件通过 [BackdropFilter] 采样背景，
/// 然后依次绘制：
/// 1. **背景模糊** — 高斯模糊采样下方内容
/// 2. **表面填充** — 半透明白色基底
/// 3. **彩色光池** — 多个径向渐变绕中心旋转
/// 4. **镜面高光** — 水平扫过的白色椭圆高光
/// 5. **边缘描边** — 上亮下暗的 1.1px 边框
/// 6. **散射光幕**（可选）— 多层变形模糊叠加
///
/// ## 使用示例
///
/// ```dart
/// HarmonyGlowMaterial(
///   borderRadius: BorderRadius.circular(28),
///   materialLevel: HarmonyGlowMaterialLevel.gentle,
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('内容'),
///   ),
/// )
/// ```
class HarmonyGlowMaterial extends StatelessWidget {
  const HarmonyGlowMaterial({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.palette = const HarmonyGlowPalette(),
    this.materialLevel = HarmonyGlowMaterialLevel.adaptive,
    this.effectTuning = const HarmonyGlowEffectTuning(),
    this.padding = EdgeInsets.zero,
    this.glowAlignment = Alignment.center,
    this.animationValue = 0,
  });

  /// 材质面板内的子组件。
  final Widget child;

  /// 面板圆角半径，默认 28px。
  final BorderRadius borderRadius;

  /// 颜色配方。
  final HarmonyGlowPalette palette;

  /// 材质等级（自适应/精致/柔和/流畅）。
  final HarmonyGlowMaterialLevel materialLevel;

  /// 效果微调参数。
  final HarmonyGlowEffectTuning effectTuning;

  /// 子组件的内边距。
  final EdgeInsetsGeometry padding;

  /// 最亮光池的中心位置。
  ///
  /// 使用 [Alignment] 坐标系：(-1,-1) 左上角，(0,0) 中心，(1,1) 右下角。
  final Alignment glowAlignment;

  /// 归一化的动画值，用于驱动镜面高光的水平位移。
  ///
  /// 范围通常为 [0, 1]，导航栏会自动传入索引切换动画的进度。
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    // --- 主题检测 ---
    final theme = HarmonyTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // 默认调色板 → 从 HarmonyUI 主题自动派生颜色（跟随 accentColor 等）
    final effectivePalette = palette == const HarmonyGlowPalette()
        ? HarmonyGlowPalette.fromTheme(theme)
        : palette;
    // 暗色背景下物理光照效果过亮，缩放至 65%
    final whiteHighlightScale = isDark ? 0.65 : 1.0;

    // --- 解析参数 ---
    final effectiveBorderRadius = borderRadius.resolve(
      Directionality.of(context),
    );
    final effectiveLevel = materialLevel.resolve(context);
    // 禁用动画时直接使用终态值，避免无意义的中间帧
    final effectiveAnimationValue = MediaQuery.disableAnimationsOf(context)
        ? 1.0
        : animationValue;
    final blurScale = effectTuning.blurScale.clamp(0.0, double.infinity);
    final shadowScale = effectTuning.shadowScale.clamp(0.0, double.infinity);
    final blurSigma = effectiveLevel.blurSigma * blurScale;
    final scatterIntensity =
        (effectiveLevel.scatterOpacity * effectTuning.scatterScale).clamp(
          0.0,
          2.0,
        );

    // --- 构建层级 ---
    return DecoratedBox(
      // 底层：盒阴影（投影）
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: effectivePalette.edgeShadow.withValues(
              alpha: (effectiveLevel.shadowOpacity * shadowScale).clamp(0, 1),
            ),
            blurRadius: effectiveLevel == HarmonyGlowMaterialLevel.smooth
                ? 12 * shadowScale
                : 24 * shadowScale,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            // 第 1 层：背景模糊 — 采样下方内容做高斯模糊
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: const SizedBox.expand(),
              ),
            ),
            // 第 2 层：散射光幕（可选）— 多层变形模糊叠加
            if (scatterIntensity > 0)
              Positioned.fill(
                child: _HarmonyBackdropScatter(
                  borderRadius: effectiveBorderRadius,
                  intensity: scatterIntensity,
                  blurSigma: blurSigma,
                  glowAlignment: glowAlignment,
                  animationValue: effectiveAnimationValue,
                  whiteHighlightScale: whiteHighlightScale,
                ),
              ),
            // 第 3 层：CustomPaint 绘制光池 + 镜面高光 + 边缘描边
            CustomPaint(
              painter: _HarmonyGlowMaterialPainter(
                borderRadius: effectiveBorderRadius,
                palette: effectivePalette,
                materialLevel: effectiveLevel,
                effectTuning: effectTuning,
                glowAlignment: glowAlignment,
                animationValue: effectiveAnimationValue,
                whiteHighlightScale: whiteHighlightScale,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _HarmonyBackdropScatter — 散射光幕（私有组件）
// =============================================================================

/// 散射光幕组件。
///
/// 使用多层经过不同矩阵变换和模糊的 [BackdropFilter] 叠加，
/// 营造光线在材质内部的散射/焦散效果。
///
/// 包含 4 层：
/// 1. 中心缩放矩阵变换的背景采样
/// 2. 左偏移大模糊光斑
/// 3. 右偏移小模糊光斑
/// 4. 散射光幕画笔（竖向椭圆带）
class _HarmonyBackdropScatter extends StatelessWidget {
  const _HarmonyBackdropScatter({
    required this.borderRadius,
    required this.intensity,
    required this.blurSigma,
    required this.glowAlignment,
    required this.animationValue,
    required this.whiteHighlightScale,
  });

  final BorderRadius borderRadius;
  final double intensity;
  final double blurSigma;
  final Alignment glowAlignment;
  final double animationValue;

  /// 白色高光强度缩放因子（暗色模式 0.65，亮色模式 1.0）。
  final double whiteHighlightScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        if (size.isEmpty) {
          return const SizedBox.shrink();
        }

        final clamped = intensity.clamp(0.0, 2.0);
        // 光池中心在面板中的像素坐标
        final center = glowAlignment.alongSize(size);
        // 基于动画值的正弦漂移，强度越大漂移越大
        final drift = math.sin(animationValue * math.pi * 2) * 2.5 * clamped;
        // 散射模糊 sigma 随强度动态调整
        final sigmaX = (blurSigma * (.65 + clamped * .32)).clamp(0.0, 42.0);
        final sigmaY = (blurSigma * (.18 + clamped * .08)).clamp(0.0, 16.0);

        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 散射层 1：中心轻微缩放矩阵变换
              _FilteredBackdrop(
                filter: ImageFilter.matrix(
                  _centerScaleMatrix(
                    size,
                    scaleX: 1 + .035 * clamped,
                    scaleY: 1 + .012 * clamped,
                    translateX: (center.dx - size.width / 2) * .018 * clamped,
                    translateY: (center.dy - size.height / 2) * .01 * clamped,
                  ),
                  filterQuality: FilterQuality.medium,
                ),
                tintOpacity: .028 * clamped * whiteHighlightScale,
              ),
              // 散射层 2：左侧偏移 + 大椭圆模糊
              Transform.translate(
                offset: Offset(-9 * clamped + drift, 0),
                child: _FilteredBackdrop(
                  filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
                  tintOpacity: .018 * clamped * whiteHighlightScale,
                ),
              ),
              // 散射层 3：右侧偏移 + 缩小模糊
              Transform.translate(
                offset: Offset(9 * clamped + drift, 0),
                child: _FilteredBackdrop(
                  filter: ImageFilter.blur(
                    sigmaX: sigmaX * .78,
                    sigmaY: sigmaY * .9,
                  ),
                  tintOpacity: .014 * clamped * whiteHighlightScale,
                ),
              ),
              // 散射层 4：竖向椭圆光幕
              CustomPaint(
                painter: _ScatterVeilPainter(
                  intensity: clamped,
                  glowAlignment: glowAlignment,
                  animationValue: animationValue,
                  whiteHighlightScale: whiteHighlightScale,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建以面板中心为原点的缩放+平移矩阵。
  ///
  /// 返回 4x4 列主序 Float64List，公式：
  /// ```
  /// [sx  0   0  0]
  /// [0   sy  0  0]
  /// [0   0   1  0]
  /// [tx  ty  0  1]
  /// ```
  static Float64List _centerScaleMatrix(
    Size size, {
    required double scaleX,
    required double scaleY,
    required double translateX,
    required double translateY,
  }) {
    // 缩放后居中补偿 + 额外平移
    final tx = size.width * (1 - scaleX) / 2 + translateX;
    final ty = size.height * (1 - scaleY) / 2 + translateY;
    return Float64List.fromList(<double>[
      scaleX, 0, 0, 0, // 第 1 列
      0, scaleY, 0, 0, // 第 2 列
      0, 0, 1, 0, // 第 3 列
      tx, ty, 0, 1, // 第 4 列（平移）
    ]);
  }
}

// =============================================================================
// _FilteredBackdrop — 带颜色叠加的模糊背景（私有组件）
// =============================================================================

/// 组合 [BackdropFilter] 和半透明白色叠加的通用小组件。
///
/// 用于散射层的每一层：先对背景做图像滤镜（模糊/矩阵变换），
/// 再覆盖一层极低不透明度的白色，形成光线散射感。
class _FilteredBackdrop extends StatelessWidget {
  const _FilteredBackdrop({required this.filter, required this.tintOpacity});

  /// 图像滤镜（模糊或矩阵变换）。
  final ImageFilter filter;

  /// 白色叠加层的不透明度。
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: filter,
      child: ColoredBox(
        color: Colors.white.withValues(alpha: tintOpacity.clamp(0.0, 1.0)),
      ),
    );
  }
}

// =============================================================================
// _ScatterVeilPainter — 散射光幕画笔（私有）
// =============================================================================

/// 绘制散射光幕的竖向椭圆带。
///
/// 在面板上绘制 4 条竖向椭圆光带（band），位置按比例分布（18%/42%/64%/82%），
/// 随动画值左右摆动，偶数带和奇数带摆动方向相反，形成交错摇曳效果。
class _ScatterVeilPainter extends CustomPainter {
  const _ScatterVeilPainter({
    required this.intensity,
    required this.glowAlignment,
    required this.animationValue,
    required this.whiteHighlightScale,
  });

  final double intensity;
  final Alignment glowAlignment;
  final double animationValue;

  /// 白色高光强度缩放因子（暗色模式 0.65，亮色模式 1.0）。
  final double whiteHighlightScale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = glowAlignment.alongSize(size);
    // 摆动相位：动画值 * 2π 的正弦
    final phase = math.sin(animationValue * math.pi * 2);
    // 4 条光带的水平基准位置（占面板宽度的比例）
    final bands = <double>[.18, .42, .64, .82];
    for (var i = 0; i < bands.length; i++) {
      // 偶数带向右摆，奇数带向左摆，形成交错效果
      final x = size.width * bands[i] + phase * (i.isEven ? 4 : -3);
      final rect = Rect.fromCenter(
        center: Offset(x, center.dy),
        width: size.width * (.16 + intensity * .045),
        height: size.height * 1.35, // 高度超出面板，形成柔和的上下渐隐
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.white.withValues(
                alpha: .08 * intensity * whiteHighlightScale,
              ),
              Colors.white.withValues(
                alpha: .024 * intensity * whiteHighlightScale,
              ),
              Colors.transparent,
            ],
            stops: const <double>[0, .45, 1],
          ).createShader(rect)
          ..blendMode = BlendMode.screen, // screen 混合模式：只增亮不增暗
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterVeilPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.glowAlignment != glowAlignment ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.whiteHighlightScale != whiteHighlightScale;
  }
}

// =============================================================================
// _HarmonyGlowMaterialPainter — 发光材质画笔（私有）
// =============================================================================

/// 绘制 [HarmonyGlowMaterial] 的核心视觉效果。
///
/// 绘制顺序：
/// 1. 表面填充（半透明基底色）
/// 2. 彩色光池（3 个径向渐变，相位各差 120°，绕中心缓慢旋转）
/// 3. 镜面高光（横向扫过的白色椭圆，模拟光照反射）
/// 4. 边缘描边（上亮下暗渐变边框，deflate 0.6px 避免裁切）
/// 5. 顶部细线（中间亮两端透明的装饰线）
class _HarmonyGlowMaterialPainter extends CustomPainter {
  const _HarmonyGlowMaterialPainter({
    required this.borderRadius,
    required this.palette,
    required this.materialLevel,
    required this.effectTuning,
    required this.glowAlignment,
    required this.animationValue,
    required this.whiteHighlightScale,
  });

  final BorderRadius borderRadius;
  final HarmonyGlowPalette palette;
  final HarmonyGlowMaterialLevel materialLevel;
  final HarmonyGlowEffectTuning effectTuning;
  final Alignment glowAlignment;
  final double animationValue;

  /// 白色高光强度缩放因子（暗色模式 0.65，亮色模式 1.0）。
  final double whiteHighlightScale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    // 无自定义光池颜色时使用默认青蓝色
    final colors = palette.glowColors.isEmpty
        ? const <Color>[Color(0xFF80D8FF)]
        : palette.glowColors;
    // --- 第 1 步：表面填充 ---
    // 使用 surfaceTint 自身的 alpha（来自 HarmonyGlowPalette.fromTheme 的主题
    // 差异化设置），乘以 surfaceScale 允许微调，不再被 fillOpacity 覆盖。
    final basePaint = Paint()
      ..color = palette.surfaceTint.withValues(
        alpha: (palette.surfaceTint.a * effectTuning.surfaceScale).clamp(
          0.0,
          1.0,
        ),
      );

    canvas.drawRRect(rrect, basePaint);

    // --- 第 2 步：彩色光池 ---
    // 每个光池以 glowAlignment 为中心，加上相位偏移的圆周运动
    final center = glowAlignment.alongSize(size);
    final largest = math.max(size.width, size.height);
    for (var i = 0; i < colors.length; i++) {
      // 相位 = 动画值 * 2π + 各颜色均匀分布的初始相位
      final phase = (animationValue + i / colors.length) * math.pi * 2;
      // 圆周偏移：半径约为面板尺寸的 9%~12%
      final offset = Offset(
        math.cos(phase) * size.width * .09,
        math.sin(phase) * size.height * .12,
      );
      // 光池半径：基础 55% 最大边长 + 索引递增
      final radius = largest * (.55 + i * .08);
      final glowRect = Rect.fromCircle(center: center + offset, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            colors[i].withValues(
              alpha: (materialLevel.glowOpacity * effectTuning.glowScale * .38)
                  .clamp(0, 1),
            ),
            colors[i].withValues(
              alpha: (materialLevel.glowOpacity * effectTuning.glowScale * .1)
                  .clamp(0, 1),
            ),
            Colors.transparent,
          ],
          stops: const <double>[0, .42, 1],
        ).createShader(glowRect)
        ..blendMode = BlendMode.plus; // plus 混合：叠加增色
      canvas.drawOval(glowRect, paint);
    }

    // --- 第 3 步：镜面高光扫描 ---
    // 横向扫过的白色椭圆，位置由 animationValue 驱动
    final sweepX = (animationValue * 2 - .5) * size.width;
    final specularRect = Rect.fromLTWH(
      sweepX,
      -size.height * .35, // 顶部超出面板，形成渐变消失
      size.width * .68,
      size.height * 1.5, // 底部超出面板
    );
    canvas.drawOval(
      specularRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(
              alpha:
                  (materialLevel.specularOpacity *
                          effectTuning.specularScale *
                          whiteHighlightScale)
                      .clamp(0, 1),
            ),
            Colors.white.withValues(
              alpha:
                  (materialLevel.specularOpacity *
                          effectTuning.specularScale *
                          whiteHighlightScale *
                          .55)
                      .clamp(0, 1),
            ),
            Colors.white.withValues(
              alpha:
                  (materialLevel.specularOpacity *
                          effectTuning.specularScale *
                          whiteHighlightScale *
                          .2)
                      .clamp(0, 1),
            ),
            Colors.transparent,
          ],
        ).createShader(specularRect)
        ..blendMode = BlendMode.screen, // screen 混合：只增亮
    );

    // --- 第 4 步：边缘描边（圆角矩形边框） ---
    // 上亮下暗的渐变边框，deflate 0.6px 避免边缘裁切
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          palette.edgeHighlight.withValues(alpha: .9),
          palette.edgeHighlight.withValues(alpha: .2),
          palette.edgeShadow.withValues(alpha: .26),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(.6), edgePaint);

    // --- 第 5 步：顶部细装饰线 ---
    // 中间亮、两端透明的 1px 横线，模拟顶部入射光
    final topLine = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          Colors.transparent,
          palette.edgeHighlight.withValues(alpha: .7),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas.drawLine(const Offset(12, 1), Offset(size.width - 12, 1), topLine);
  }

  @override
  bool shouldRepaint(covariant _HarmonyGlowMaterialPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.palette != palette ||
        oldDelegate.materialLevel != materialLevel ||
        oldDelegate.effectTuning != effectTuning ||
        oldDelegate.glowAlignment != glowAlignment ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.whiteHighlightScale != whiteHighlightScale;
  }
}

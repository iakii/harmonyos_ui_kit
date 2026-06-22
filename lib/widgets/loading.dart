import 'dart:math' as math;

import 'package:harmonyos_ui/harmonyos_ui.dart';

/// 3D 立体环绕 Loading 指示器。
///
/// 圆环在 3D 空间倾斜，圆点沿椭圆轨道环绕并带残影拖尾，同时整体上下弹跳。
class Loading extends StatefulWidget {
  /// [color] 圆环/圆点/残影的颜色，默认白色。
  /// [size] 组件尺寸（宽高相等），默认 128。
  const Loading({super.key, this.color, this.size = 128});

  final Color? color;
  final double size;

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: FittedBox(
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final bounceY =
                      math.sin(_controller.value * 2 * math.pi) * 10;
                  return Transform.translate(
                    offset: Offset(0, bounceY),
                    child: CustomPaint(
                      size: Size(100, 100),
                      painter: _CircleRingPainter(
                        animationValue: _controller.value,
                        color: widget.color ?? theme.accentColor,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D 立体环绕绘制器。
///
/// 圆环位于 3D 空间的「正中间」，绕 X 轴前倾约 60° 再绕 Z 轴旋转 45°，
/// 使得圆环在当前视角下呈扁平椭圆，长轴从左下角指向右上角。
/// 圆点沿椭圆轨道环绕，z 深度影响其大小和透明度，产生远近透视效果。
class _CircleRingPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double size;

  _CircleRingPainter({
    required this.animationValue,
    required this.color,
    required this.size,
  });

  /// X 轴前倾角度（弧度），决定椭圆的扁平程度。
  static const double _tiltX = math.pi / 2; // 60°

  /// Z 轴旋转角度（弧度），让椭圆长轴沿左下→右上对角线。
  static const double _rotateZ = math.pi * 7 / 8; // 135°（45° + 90°）

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final rx = size * 0.4; // 水平半径
    final ry = rx * math.cos(_tiltX); // 垂直半径（3D 透视压缩）

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotateZ);

    // ---- 圆环 ----
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size * 0.5,
      height: size * 0.5,
    );
    canvas.drawArc(rect, 0, math.pi * 2, false, ringPaint);

    // ---- 圆点 + 残影（含 3D 深度）----
    final theta = -animationValue * 2 * math.pi - math.pi / 4;

    const trailCount = 10;
    for (int i = trailCount; i >= 1; i--) {
      final trailTheta = theta + i * 0.35;
      final (x, y, scale) = _project(trailTheta, rx, ry);
      final progress = i / (trailCount + 1);
      final trailOpacity = (1.0 - progress) * scale;
      final trailRadius = (1.5 + 3.5 * (1.0 - progress)) * scale;

      final trailPaint = Paint()
        ..color = color.withValues(alpha: trailOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), trailRadius, trailPaint);
    }

    // 主圆点
    final (dotX, dotY, dotScale) = _project(theta, rx, ry);
    final dotRadius = 5.0 * dotScale;
    final dotOpacity = dotScale.clamp(0.3, 1.0);

    final dotPaint = Paint()
      ..color = color.withValues(alpha: dotOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), dotRadius, dotPaint);

    canvas.restore();
  }

  /// 3D → 2D 投影。
  ///
  /// 返回 `(x, y, scale)`：
  /// - `x`, `y` 是椭圆上的 2D 坐标；
  /// - `scale` 是基于 z 深度的缩放因子（近大远小，0.6~1.4）。
  (double, double, double) _project(double theta, double rx, double ry) {
    final x = math.cos(theta) * rx;
    final y = math.sin(theta) * ry;
    // z 深度：sin(theta) ∈ [-1, 1]，负值 = 靠近观察者（大 & 亮），正值 = 远离（小 & 暗）
    final z = math.sin(theta);
    final scale = 1.0 - z * 0.4; // z=-1 → 1.4, z=0 → 1.0, z=1 → 0.6
    return (x, y, scale);
  }

  @override
  bool shouldRepaint(covariant _CircleRingPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color ||
      oldDelegate.size != size;
}

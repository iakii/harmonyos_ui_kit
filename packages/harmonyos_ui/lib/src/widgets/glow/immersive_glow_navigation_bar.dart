/// 带 HDS 风格沉浸式光效的浮动底部导航栏。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../styles/theme.dart';
import 'glow_material.dart';
import 'glow_material_level.dart';
import 'glow_navigation_item.dart';
import 'glow_palette.dart';

// =============================================================================
// HarmonyImmersiveGlowNavigationBar — 沉浸式发光底部导航栏
// =============================================================================

/// 带 HDS 风格沉浸式光效的浮动底部导航栏。
///
/// ## 特性
///
/// - **沉浸式发光材质**：整合 [HarmonyGlowMaterial] 的全部视觉效果
/// - **弹簧物理交互**：按压和拖拽时面板产生弹性形变（缩放+平移），释放后回弹
/// - **光效跟随**：光池中心随手指位置移动，形成焦散拖尾
/// - **索引切换动画**：选中项切换时光池平滑过渡
/// - **按压反馈**：被按下的图标缩小至 88%
///
/// ## 使用示例
///
/// ```dart
/// HarmonyImmersiveGlowNavigationBar(
///   currentIndex: _currentIndex,
///   onTap: (index) => setState(() => _currentIndex = index),
///   items: const [
///     HarmonyGlowNavigationItem(icon: Icon(Icons.home), label: '首页'),
///     HarmonyGlowNavigationItem(icon: Icon(Icons.search), label: '搜索'),
///     HarmonyGlowNavigationItem(icon: Icon(Icons.person), label: '我的'),
///   ],
/// )
/// ```
class HarmonyImmersiveGlowNavigationBar extends StatefulWidget {
  const HarmonyImmersiveGlowNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.palette = const HarmonyGlowPalette(),
    this.materialLevel = HarmonyGlowMaterialLevel.adaptive,
    this.effectTuning = const HarmonyGlowEffectTuning(),
    this.height = 72,
    this.widthFactor = .86,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 28),
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.iconSize = 28,
    this.labelStyle,
    this.showLabels = true,
    this.includeBottomSafeArea = true,
    this.enableInteractionEffect = true,
    this.interactionFadeDuration = const Duration(milliseconds: 260),
    this.animationDuration = const Duration(milliseconds: 360),
    this.curve = Curves.easeOutCubic,
  }) : assert(items.length >= 2),
       assert(currentIndex >= 0),
       assert(currentIndex < items.length),
       assert(widthFactor == null || widthFactor > 0 && widthFactor <= 1);

  /// 导航项列表，至少 2 项。
  final List<HarmonyGlowNavigationItem> items;

  /// 当前选中项索引。
  final int currentIndex;

  /// 点击回调，参数为被点击项的索引。
  final ValueChanged<int> onTap;

  /// 颜色配方。
  final HarmonyGlowPalette palette;

  /// 材质等级。
  final HarmonyGlowMaterialLevel materialLevel;

  /// 效果微调参数。
  final HarmonyGlowEffectTuning effectTuning;

  /// 导航栏高度，默认 72px。
  final double height;

  /// 宽度因子（占父容器宽度的比例），默认 0.86。
  ///
  /// 设为 null 则占满父容器宽度。
  final double? widthFactor;

  /// 外边距，默认 `EdgeInsets.fromLTRB(16, 0, 16, 28)`。
  final EdgeInsetsGeometry margin;

  /// 圆角半径，默认 32px。
  final BorderRadius borderRadius;

  /// 图标尺寸，默认 28px。
  final double iconSize;

  /// 标签文字样式。
  final TextStyle? labelStyle;

  /// 是否显示标签文字，默认 true。
  final bool showLabels;

  /// 是否包含底部安全区，默认 true。
  final bool includeBottomSafeArea;

  /// 是否启用手势交互效果（按压光效+弹性形变），默认 true。
  final bool enableInteractionEffect;

  /// 交互效果（光斑亮起/熄灭）的过渡时长，默认 260ms。
  final Duration interactionFadeDuration;

  /// 索引切换动画时长，默认 360ms。
  final Duration animationDuration;

  /// 索引切换动画曲线，默认 [Curves.easeOutCubic]。
  final Curve curve;

  @override
  State<HarmonyImmersiveGlowNavigationBar> createState() =>
      _HarmonyImmersiveGlowNavigationBarState();
}

// =============================================================================
// _HarmonyImmersiveGlowNavigationBarState — 导航栏状态管理
// =============================================================================

/// 导航栏的状态管理类。
///
/// 管理三套动画/物理系统：
/// 1. **_controller**：索引切换动画（[AnimationController]）
/// 2. **_interactionController**：交互光效淡入淡出（[AnimationController]）
/// 3. **_elasticTicker**：弹簧物理模拟（自定义 [Ticker]），每帧更新形变状态
///
/// ## 弹簧物理
///
/// 使用解析的阻尼谐振子模型：
/// - stiffness（刚度）：68 + elasticScale * 24
/// - damping（阻尼）：14 + (1-elasticScale) * 4
/// - 每帧：acceleration = (target - current) * stiffness
/// - 速度衰减：velocity *= exp(-damping * dt)
/// - 当位移 < 0.003px 且速度 < 0.01px/frame 时停止 ticker
class _HarmonyImmersiveGlowNavigationBarState
    extends State<HarmonyImmersiveGlowNavigationBar>
    with TickerProviderStateMixin {
  // --- 核心控制器 ---
  final GlobalKey _barKey = GlobalKey();
  late final AnimationController _controller; // 索引切换动画
  late final AnimationController _interactionController; // 交互光效动画
  late final Ticker _elasticTicker; // 弹簧物理 ticker
  late Animation<double> _indexAnimation; // 当前动画值
  late double _selectedIndex; // 目标选中索引

  // --- 弹簧物理状态：光斑位置 ---
  Alignment _targetInteractionAlignment = Alignment.center; // 目标位置
  Alignment _springInteractionAlignment = Alignment.center; // 当前位置（弹簧跟随）
  Offset _springVelocity = Offset.zero; // 弹簧速度

  // --- 弹簧物理状态：弹性形变 ---
  Offset _targetElasticPull = Offset.zero; // 目标拉伸量
  Offset _elasticPull = Offset.zero; // 当前拉伸量（弹簧跟随）
  Offset _elasticPullVelocity = Offset.zero; // 拉伸速度

  // --- 手势状态 ---
  Offset? _pointerDownLocal; // 按下时的本地坐标
  bool _isPointerActive = false; // 手指是否在面板上
  int? _pressedIndex; // 当前被按下的项索引

  // --- ticker 时间追踪 ---
  Duration? _lastElasticElapsed; // 上一帧的 elapsed，用于计算 dt

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex.toDouble();
    // 索引动画控制器：初始值 1.0（表示动画已完成）
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..value = 1;
    // 交互光效控制器：初始值 0.0（光效熄灭）
    _interactionController = AnimationController(
      vsync: this,
      duration: widget.interactionFadeDuration,
    );
    // 弹性物理 ticker
    _elasticTicker = createTicker(_tickElasticAlignment);
    // 初始动画值 = 当前选中索引（无动画）
    _indexAnimation = AlwaysStoppedAnimation<double>(_selectedIndex);
  }

  @override
  void didUpdateWidget(covariant HarmonyImmersiveGlowNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新动画时长
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
    }
    if (oldWidget.interactionFadeDuration != widget.interactionFadeDuration) {
      _interactionController.duration = widget.interactionFadeDuration;
    }

    // 索引变化时：创建 Tween 动画
    if (oldWidget.currentIndex != widget.currentIndex) {
      final beginIndex = _indexAnimation.value.clamp(
        0.0,
        (widget.items.length - 1).toDouble(),
      );
      _indexAnimation = Tween<double>(
        begin: beginIndex,
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _selectedIndex = widget.currentIndex.toDouble();
      _controller.forward(from: 0); // 从 0 开始正向播放
    }
  }

  @override
  void dispose() {
    _elasticTicker.dispose();
    _controller.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  // --- 弹簧物理模拟 ---

  /// 每帧调用的弹簧物理 tick。
  ///
  /// 使用阻尼谐振子模型同时驱动两组弹簧：
  /// - 光斑位置弹簧：[_springInteractionAlignment] → [_targetInteractionAlignment]
  /// - 弹性形变弹簧：[_elasticPull] → [_targetElasticPull]
  ///
  /// 当两组弹簧都接近静止时自动停止 ticker 以节省性能。
  void _tickElasticAlignment(Duration elapsed) {
    final previousElapsed = _lastElasticElapsed;
    _lastElasticElapsed = elapsed;
    if (previousElapsed == null) {
      return; // 第一帧，跳过
    }

    // 计算时间步长（秒），限制范围防止大帧间隔导致数值爆炸
    final dt = ((elapsed - previousElapsed).inMicroseconds / 1000000).clamp(
      .001,
      .032,
    );

    // --- 光斑位置弹簧 ---
    final elasticScale = widget.effectTuning.elasticScale.clamp(.0, 2.5);
    final stiffness = 68.0 + elasticScale * 24.0;
    final damping = 14.0 + (1.0 - elasticScale.clamp(0, 1)) * 4.0;
    final target = Offset(
      _targetInteractionAlignment.x,
      _targetInteractionAlignment.y,
    );
    final current = Offset(
      _springInteractionAlignment.x,
      _springInteractionAlignment.y,
    );
    // 加速度 = 劲度系数 * 位移差
    final acceleration = (target - current) * stiffness;
    // 速度衰减因子
    final dampingFactor = math.exp(-damping * dt);
    // 半隐式欧拉积分：先更新速度，再更新位置
    final nextVelocity = (_springVelocity + acceleration * dt) * dampingFactor;
    final next = current + nextVelocity * dt;

    // --- 弹性形变弹簧（同样的物理模型） ---
    final pullAcceleration = (_targetElasticPull - _elasticPull) * stiffness;
    final nextPullVelocity =
        (_elasticPullVelocity + pullAcceleration * dt) * dampingFactor;
    final nextPull = _elasticPull + nextPullVelocity * dt;

    // 更新状态
    setState(() {
      _springVelocity = nextVelocity;
      _springInteractionAlignment = Alignment(
        next.dx.clamp(-1.12, 1.12),
        next.dy.clamp(-1.12, 1.12),
      );
      _elasticPullVelocity = nextPullVelocity;
      _elasticPull = Offset(
        nextPull.dx.clamp(-.24, .24),
        nextPull.dy.clamp(-.18, .18),
      );
    });

    // 静止检测：位移和速度都足够小时停止 ticker
    final distance = (target - next).distance;
    if (_interactionController.isDismissed &&
        distance < .003 &&
        nextVelocity.distance < .01 &&
        _targetElasticPull.distance < .001 &&
        nextPull.distance < .001 &&
        nextPullVelocity.distance < .01) {
      _elasticTicker.stop();
      _lastElasticElapsed = null;
      // 重置为零，下次启动时从静止开始
      _springVelocity = Offset.zero;
      _elasticPullVelocity = Offset.zero;
      _elasticPull = Offset.zero;
    }
  }

  /// 确保弹性 ticker 在运行（延迟启动）。
  void _ensureElasticTicker() {
    if (!_elasticTicker.isActive) {
      _lastElasticElapsed = null;
      _elasticTicker.start();
    }
  }

  // --- 坐标计算辅助 ---

  /// 根据本地坐标计算对应的导航项索引。
  ///
  /// 将面板宽度均分给每个项，取 floor。
  int _itemIndexForLocalPosition(Offset local, Size size) {
    final itemWidth = size.width / widget.items.length;
    return (local.dx / itemWidth).floor().clamp(0, widget.items.length - 1);
  }

  /// 获取导航栏的 [RenderBox]。
  RenderBox? _barRenderBox() {
    final renderObject = _barKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject;
    }
    return null;
  }

  /// 根据本地坐标计算拖拽拉伸量。
  ///
  /// 综合两部分：
  /// 1. **拖拽分量**：手指位移方向的非线性映射（指数衰减）
  /// 2. **边缘分量**：靠近面板左右边缘时产生向外的拉力
  Offset _dragPullForLocalPosition(Offset local, Size size) {
    final downLocal = _pointerDownLocal ?? local;
    // 归一化拖拽位移 [-2, 2]
    final rawDrag = Offset(
      (local.dx - downLocal.dx) / size.width * 2,
      (local.dy - downLocal.dy) / size.height * 2,
    );
    // 非线性映射：用 1-exp(-|x|*k) 使小位移敏感、大位移饱和
    final dragPull = Offset(
      rawDrag.dx.sign * (1 - math.exp(-rawDrag.dx.abs() * 2.4)) * .16,
      rawDrag.dy.sign * (1 - math.exp(-rawDrag.dy.abs() * 2.0)) * .11,
    );

    // 边缘拉力：手指靠近面板边缘时向外拉
    final rawX = local.dx / size.width * 2 - 1; // [-1, 1]
    final edgeDistance = (rawX.abs() - .72).clamp(0.0, 1.2);
    final edgePull = Offset(
      rawX.sign * (1 - math.exp(-edgeDistance * 2.8)) * .07,
      0,
    );
    return dragPull + edgePull;
  }

  /// 根据本地坐标计算点击拉伸量。
  ///
  /// 首项向左下拉伸，末项向右下拉伸，中间项仅向下拉伸。
  Offset _tapPullForLocalPosition(Offset local, Size size) {
    final index = _itemIndexForLocalPosition(local, size);
    final lastIndex = widget.items.length - 1;
    if (index == 0) {
      return const Offset(-.055, .012);
    }
    if (index == lastIndex) {
      return const Offset(.055, .012);
    }
    return const Offset(0, .035);
  }

  // --- 手势处理 ---

  /// 手指按下：记录位置、启动交互光效和弹簧物理。
  void _beginInteraction(PointerDownEvent event) {
    if (!widget.enableInteractionEffect) {
      return;
    }

    final renderObject = _barRenderBox();
    if (renderObject == null) {
      return;
    }

    final local = renderObject.globalToLocal(event.position);
    final size = renderObject.size;
    final rawX = local.dx / size.width * 2 - 1;
    final rawY = local.dy / size.height * 2 - 1;
    final x = rawX.clamp(-1.0, 1.0);
    final y = rawY.clamp(-1.0, 1.0);

    setState(() {
      _isPointerActive = true;
      _pointerDownLocal = local;
      _pressedIndex = _itemIndexForLocalPosition(local, size);
      _targetInteractionAlignment = Alignment(x, y);
      _targetElasticPull = _tapPullForLocalPosition(local, size);
    });
    _ensureElasticTicker();
    // 交互光效淡入
    _interactionController.forward(from: 0);
  }

  /// 手指移动：更新光斑目标和弹性拉伸。
  void _updateInteraction(PointerMoveEvent event) {
    if (!widget.enableInteractionEffect || !_isPointerActive) {
      return;
    }

    final renderObject = _barRenderBox();
    if (renderObject == null) {
      return;
    }

    final local = renderObject.globalToLocal(event.position);
    final size = renderObject.size;
    final rawX = local.dx / size.width * 2 - 1;
    final rawY = local.dy / size.height * 2 - 1;
    final x = rawX.clamp(-1.0, 1.0);
    final y = rawY.clamp(-1.0, 1.0);
    final downLocal = _pointerDownLocal ?? local;
    final dragDistance = (local - downLocal).distance;
    // 移动超过 8px 视为拖拽，清除按压索引
    final isDraggingInteraction = dragDistance > 8;

    setState(() {
      _targetInteractionAlignment = Alignment(x, y);
      _targetElasticPull = _dragPullForLocalPosition(local, size);
      _pressedIndex = isDraggingInteraction
          ? null
          : _itemIndexForLocalPosition(local, size);
    });
    _ensureElasticTicker();
  }

  /// 手指抬起/取消：淡出交互光效，弹簧回弹到初始状态。
  void _endInteraction() {
    if (widget.enableInteractionEffect) {
      setState(() {
        _isPointerActive = false;
        _pointerDownLocal = null;
        _pressedIndex = null;
      });
      _interactionController.reverse();
      // 目标复位：光斑留在当前位置，拉伸量归零
      _targetInteractionAlignment = _springInteractionAlignment;
      _targetElasticPull = Offset.zero;
      _ensureElasticTicker();
    }
  }

  // --- 构建 ---

  @override
  Widget build(BuildContext context) {
    // --- 主题检测 ---
    final theme = HarmonyTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // 默认调色板 → 从 HarmonyUI 主题自动派生颜色（跟随 accentColor 等）
    final effectivePalette = widget.palette == const HarmonyGlowPalette()
        ? HarmonyGlowPalette.fromTheme(theme)
        : widget.palette;
    // 暗色背景下物理光照效果过亮，缩放至 65%
    final whiteHighlightScale = isDark ? 0.65 : 1.0;

    final textScaler = MediaQuery.textScalerOf(context);
    final bottomPadding = widget.includeBottomSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;

    return Padding(
      padding: widget.margin.add(EdgeInsets.only(bottom: bottomPadding)),
      child: FractionallySizedBox(
        widthFactor: widget.widthFactor,
        child: SizedBox(
          key: _barKey,
          height: widget.height,
          // Listener 捕获原始指针事件（不阻止子组件的点击）
          child: Listener(
            onPointerDown: _beginInteraction,
            onPointerMove: _updateInteraction,
            onPointerUp: (_) => _endInteraction(),
            onPointerCancel: (_) => _endInteraction(),
            // AnimatedBuilder 监听双控制器，每帧重建光效参数
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _controller,
                _interactionController,
              ]),
              builder: (context, child) {
                // --- 计算光效参数 ---

                // 当前可视化索引（可能是小数，表示动画中间态）
                final visualIndex = _indexAnimation.value
                    .clamp(0, widget.items.length - 1)
                    .toDouble();
                // 光池水平位置：将索引映射到 Alignment x 坐标 [-1, 1]
                final glowX = widget.items.length == 1
                    ? 0.0
                    : (visualIndex / (widget.items.length - 1)) * 2 - 1;
                final baseAlignment = Alignment(glowX, .08);

                final interactionProgress = _interactionController.value;
                final effectiveLevel = widget.materialLevel.resolve(context);

                // 光斑位置 = 索引位置 + 手指交互偏移（lerp 混合）
                final pointerAlignment =
                    Alignment.lerp(
                      baseAlignment,
                      _springInteractionAlignment,
                      interactionProgress,
                    ) ??
                    baseAlignment;

                // 拉伸能量：综合弹簧速度和位移
                final stretchEnergy =
                    (_springVelocity.distance * .04 * interactionProgress)
                        .clamp(0.0, 1.0);
                final elasticScale = widget.effectTuning.elasticScale.clamp(
                  .0,
                  2.5,
                );
                final pull = _elasticPull * elasticScale;
                final horizontalEnergy = pull.dx.abs().clamp(0.0, 1.0);
                final verticalEnergy = pull.dy.abs().clamp(0.0, 1.0);
                final pullEnergy = pull.distance.clamp(0.0, 1.0);

                // 弹性缩放：水平拉伸以横向能量为主，垂直拉伸以纵向能量为主
                const stretchAlignment = Alignment.center;
                final stretchX =
                    1 + horizontalEnergy * .34 + verticalEnergy * .035;
                final stretchY =
                    1 + verticalEnergy * .24 - horizontalEnergy * .025;

                // 弹性平移微调
                final elasticNudge = Offset(
                  pull.dx * 10,
                  pull.dy * 7 +
                      _springVelocity.dy *
                          .025 *
                          interactionProgress *
                          elasticScale,
                );

                // --- 构建带形变的发光材质 ---
                return Transform.translate(
                  offset: elasticNudge,
                  child: Transform.scale(
                    alignment: stretchAlignment,
                    scaleX: stretchX,
                    scaleY: stretchY,
                    child: HarmonyGlowMaterial(
                      borderRadius: widget.borderRadius,
                      palette: effectivePalette,
                      materialLevel: effectiveLevel,
                      effectTuning: widget.effectTuning,
                      glowAlignment: pointerAlignment,
                      animationValue: .5 + interactionProgress * .5,
                      child: CustomPaint(
                        painter: _NavigationGlowPainter(
                          itemCount: widget.items.length,
                          visualIndex: visualIndex,
                          palette: effectivePalette,
                          materialLevel: effectiveLevel,
                          effectTuning: widget.effectTuning,
                          interactionAlignment: pointerAlignment,
                          targetInteractionAlignment:
                              _targetInteractionAlignment,
                          interactionProgress: interactionProgress,
                          elasticEnergy: math.max(stretchEnergy, pullEnergy),
                          elasticPull: pull,
                          progress: _controller.value,
                          whiteHighlightScale: whiteHighlightScale,
                        ),
                        child: child, // Row of _NavigationButton
                      ),
                    ),
                  ),
                );
              },
              // 子组件：导航按钮行（不随动画重建）
              child: Row(
                children: List<Widget>.generate(widget.items.length, (index) {
                  return Expanded(
                    child: _NavigationButton(
                      item: widget.items[index],
                      selected: index == widget.currentIndex,
                      pressed: index == _pressedIndex,
                      onTap: () => widget.onTap(index),
                      palette: effectivePalette,
                      iconSize: widget.iconSize,
                      labelStyle: widget.labelStyle,
                      showLabel: widget.showLabels,
                      textScaler: textScaler,
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _NavigationButton — 导航按钮（私有组件）
// =============================================================================

/// 单个导航按钮组件。
///
/// 包含图标（支持选中态切换）和文字标签。按下时图标缩小至 88%，
/// 松手时弹性回弹。使用 [Semantics] 提供无障碍支持。
class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.pressed,
    required this.onTap,
    required this.palette,
    required this.iconSize,
    required this.labelStyle,
    required this.showLabel,
    required this.textScaler,
  });

  final HarmonyGlowNavigationItem item;
  final bool selected;
  final bool pressed;
  final VoidCallback onTap;
  final HarmonyGlowPalette palette;
  final double iconSize;
  final TextStyle? labelStyle;
  final bool showLabel;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // 根据选中/未选中选择颜色
    final color = selected
        ? theme.accentColor
        : isDark
        ? Colors.white
        : palette.inactiveColor;
    // 标签样式：优先用传入的，其次用主题的 labelMedium，最后回退
    final baseStyle =
        labelStyle ??
        Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.05,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    return Semantics(
      button: true,
      selected: selected,
      label: item.tooltip ?? item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: IconTheme.merge(
          data: IconThemeData(color: color, size: iconSize),
          child: DefaultTextStyle(
            style: baseStyle.copyWith(color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // 图标：按下时缩小至 88%，松手弹性回弹
                AnimatedScale(
                  scale: pressed ? .88 : 1,
                  duration: Duration(milliseconds: pressed ? 80 : 360),
                  curve: pressed ? Curves.easeOutCubic : Curves.elasticOut,
                  child: selected ? item.activeIcon ?? item.icon : item.icon,
                ),
                if (showLabel) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    textScaler: textScaler.clamp(
                      minScaleFactor: 1,
                      maxScaleFactor: 1.2, // 限制最大缩放到 120%
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _NavigationGlowPainter — 导航交互光效画笔（私有）
// =============================================================================

/// 在 [HarmonyImmersiveGlowNavigationBar] 中绘制交互光效。
///
/// **仅在手指按下时绘制**（[interactionProgress] > 0），包括：
/// 1. **彩色焦散光斑**：3 个径向渐变光斑在手指位置，颜色循环偏移
/// 2. **镜面透镜**：手指位置的白色椭圆高光
/// 3. **弹性拖尾**：拖拽方向上的拉伸光斑（有 elasticEnergy 时）
///
/// 设计原则：遵循原生 HDS —— 仅指针按下时显示亮色按压透镜，
/// 选中索引切换不应留下额外的白色闪光。
class _NavigationGlowPainter extends CustomPainter {
  const _NavigationGlowPainter({
    required this.itemCount,
    required this.visualIndex,
    required this.palette,
    required this.materialLevel,
    required this.effectTuning,
    required this.interactionAlignment,
    required this.targetInteractionAlignment,
    required this.interactionProgress,
    required this.elasticEnergy,
    required this.elasticPull,
    required this.progress,
    required this.whiteHighlightScale,
  });

  final int itemCount;
  final double visualIndex;
  final HarmonyGlowPalette palette;
  final HarmonyGlowMaterialLevel materialLevel;
  final HarmonyGlowEffectTuning effectTuning;
  final Alignment interactionAlignment;
  final Alignment targetInteractionAlignment;
  final double interactionProgress;
  final double elasticEnergy;
  final Offset elasticPull;
  final double progress;

  /// 白色高光强度缩放因子（暗色模式 0.65，亮色模式 1.0）。
  final double whiteHighlightScale;

  @override
  void paint(Canvas canvas, Size size) {
    if (itemCount <= 0) {
      return;
    }

    final itemWidth = size.width / itemCount;
    final colors = palette.glowColors.isEmpty
        ? const <Color>[Color(0xFF80D8FF)]
        : palette.glowColors;

    // 仅在手指按下时绘制交互光效
    if (interactionProgress > 0) {
      // 光斑当前位置（弹簧跟踪位置）
      final pointerCenter = interactionAlignment.alongSize(size);
      // 目标位置（手指实际位置）
      final targetCenter = targetInteractionAlignment.alongSize(size);
      // 滞后向量：弹簧位置到目标位置的差
      final lagVector = targetCenter - pointerCenter;

      // --- 第 1 层：彩色焦散光斑 ---
      for (var i = 0; i < colors.length; i++) {
        final offset = Offset(
          (i - 1) * itemWidth * .22,
          (i.isEven ? -1 : 1) * 8,
        );
        final causticRect = Rect.fromCenter(
          center: pointerCenter + offset,
          width: itemWidth * (1.28 + i * .18),
          height: size.height * .95,
        );
        canvas.drawOval(
          causticRect,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                colors[i].withValues(
                  alpha:
                      (materialLevel.glowOpacity *
                              effectTuning.glowScale *
                              interactionProgress *
                              .72)
                          .clamp(0, 1),
                ),
                colors[i].withValues(
                  alpha:
                      (materialLevel.glowOpacity *
                              effectTuning.glowScale *
                              interactionProgress *
                              .18)
                          .clamp(0, 1),
                ),
                Colors.transparent,
              ],
            ).createShader(causticRect)
            ..blendMode = BlendMode.plus,
        );
      }

      // --- 第 2 层：镜面透镜（手指位置的白色椭圆高光） ---
      final lensRect = Rect.fromCenter(
        center: pointerCenter,
        width: itemWidth * (1.14 + elasticEnergy * .18),
        height: size.height * (.74 - elasticEnergy * .035),
      );
      canvas.drawOval(
        lensRect,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.white.withValues(
                alpha:
                    (.3 *
                            effectTuning.specularScale *
                            interactionProgress *
                            whiteHighlightScale)
                        .clamp(0, 1),
              ),
              Colors.white.withValues(
                alpha:
                    (.08 *
                            effectTuning.specularScale *
                            interactionProgress *
                            whiteHighlightScale)
                        .clamp(0, 1),
              ),
              Colors.transparent,
            ],
          ).createShader(lensRect)
          ..blendMode = BlendMode.screen,
      );

      // --- 第 3 层：弹性拖尾光斑 ---
      // 当有弹性形变能量时，在拖拽反方向绘制拖尾光斑
      if (elasticEnergy > 0) {
        // 拖拽方向单位向量
        final dragDirection = elasticPull.distance == 0
            ? Offset.zero
            : elasticPull / elasticPull.distance;
        // 边缘偏移：拖拽反方向偏移
        final edgeBias = Offset(
          dragDirection.dx * itemWidth * .1,
          dragDirection.dy * size.height * .055,
        );
        final tailRect = Rect.fromCenter(
          // 拖尾中心：手指位置 - 滞后向量 * 32% + 边缘偏移
          center: pointerCenter - lagVector * .32 + edgeBias,
          width:
              (itemWidth *
                      (1.08 +
                          elasticEnergy * .28 +
                          elasticPull.dx.abs().clamp(0.0, 1.0) * .16))
                  .clamp(itemWidth, itemWidth * 1.75),
          height:
              size.height *
              (.46 +
                  elasticEnergy * .08 +
                  elasticPull.dy.abs().clamp(0.0, 1.0) * .12),
        );
        canvas.drawOval(
          tailRect,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                Colors.white.withValues(
                  alpha:
                      (.16 *
                              effectTuning.specularScale *
                              interactionProgress *
                              elasticEnergy *
                              whiteHighlightScale)
                          .clamp(0, 1),
                ),
                colors.first.withValues(
                  alpha:
                      (.1 *
                              effectTuning.glowScale *
                              interactionProgress *
                              elasticEnergy)
                          .clamp(0, 1),
                ),
                Colors.transparent,
              ],
            ).createShader(tailRect)
            ..blendMode = BlendMode.screen,
        );
      }
    }

    // 原生 HDS 仅在指针按下时暴露亮色按压透镜。
    // 选中索引切换不应留下单独的白色闪光。
  }

  @override
  bool shouldRepaint(covariant _NavigationGlowPainter oldDelegate) {
    return oldDelegate.itemCount != itemCount ||
        oldDelegate.visualIndex != visualIndex ||
        oldDelegate.palette != palette ||
        oldDelegate.materialLevel != materialLevel ||
        oldDelegate.effectTuning != effectTuning ||
        oldDelegate.interactionAlignment != interactionAlignment ||
        oldDelegate.targetInteractionAlignment != targetInteractionAlignment ||
        oldDelegate.interactionProgress != interactionProgress ||
        oldDelegate.elasticEnergy != elasticEnergy ||
        oldDelegate.elasticPull != elasticPull ||
        oldDelegate.progress != progress ||
        oldDelegate.whiteHighlightScale != whiteHighlightScale;
  }
}

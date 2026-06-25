import 'package:flutter/material.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

/// 回到顶部悬浮按钮。
///
/// 带有缩放入场动画，点击后 [scrollController] 平滑滚动到顶部。
/// 继承自 [_BackToTopButton]（原 `rust_daily_list_tab.dart` 私有组件）。
class BackToTopButton extends StatefulWidget {
  const BackToTopButton({super.key, required this.scrollController});

  /// 绑定的滚动控制器。
  final ScrollController scrollController;

  @override
  State<BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<BackToTopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 20,
          icon: const Icon(HMIcons.arrowshapeUpToLine),
          onPressed: () {
            widget.scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }
}

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// HarmonyOS-style app bar (title bar) with immersive light effect.
///
/// Implements the HarmonyOS Design System (HDS) title bar specifications:
/// - **Default height**: 56 vp (single line)
/// - **Immersive light effect** (沉浸光感): frosted glass via [BackdropFilter]
///   with a semi-transparent background — the HarmonyOS panel blur aesthetic.
/// - **1 px bottom divider** when opaque, hidden when immersive for a cleaner look.
///
/// Implements [PreferredSizeWidget] so it can be used directly as
/// [Scaffold.appBar].
///
/// ## Example
///
/// ```dart
/// Scaffold(
///   appBar: HosAppBar(title: '设置'),
///   body: ListView(children: [...]),
/// )
/// ```
///
/// ## Design tokens
///
/// | Property | Light mode | Dark mode |
/// |----------|-----------|-----------|
/// | Immersive mask | `Colors.white` @ 70 % opacity | `Color(0xFF1E1E1E)` @ 70 % |
/// | Title | `theme.typography.title2` | same |
/// | Divider | 1 px `theme.dividerColor` | same |
///
/// See the [HarmonyOS Design Guide](https://developer.huawei.com/consumer/cn/doc/design-guides/titlebar-0000001929628982)
/// for the full specification.
class HosAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a HarmonyOS app bar.
  const HosAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.height = 92.0,
    this.immersive = true,
    this.blurSigmaX = 40.0,
    this.blurSigmaY = 92.0,
    this.backgroundColor,
    this.dividerColor,
  });

  /// Title shown in the center of the app bar.
  final String? title;

  /// Leading widget (before the title). If omitted and the route can pop,
  /// a back button is shown by default — see [HosAppBar.defaultLeading].
  final Widget? leading;

  /// Action widgets (after the title). Wrapped in a [Row] so multiple
  /// actions can be provided.
  final List<Widget>? actions;

  /// Height of the app bar. Defaults to 82 vp (HDS spec).
  final double height;

  /// Whether to enable the immersive light effect (沉浸光感).
  ///
  /// When enabled, the bar renders with a [BackdropFilter] frosted-glass blur
  /// and a semi-transparent background, creating the HarmonyOS panel-blur
  /// aesthetic on the title bar.
  ///
  /// Defaults to `true`.
  final bool immersive;

  /// Horizontal blur intensity for the immersive effect.
  ///
  /// Defaults to 40. Higher values produce a stronger blur.
  final double blurSigmaX;

  /// Vertical blur intensity for the immersive effect.
  ///
  /// Defaults to 40. Higher values produce a stronger blur.
  final double blurSigmaY;

  /// Override for the bar background color.
  ///
  /// When not provided the immersive mode defaults to a semi-transparent
  /// white (light) or dark surface (dark); otherwise falls back to
  /// [HarmonyThemeData.surfaceColor].
  final Color? backgroundColor;

  /// Override for the bottom divider color.
  ///
  /// Defaults to [HarmonyThemeData.dividerColor].
  final Color? dividerColor;

  /// A default back-button leading widget that shows a back arrow when the
  /// current route can pop.
  ///
  /// Use this as a convenience when you want the standard back behaviour:
  /// ```dart
  /// HosAppBar(title: 'Details', leading: HosAppBar.defaultLeading(context))
  /// ```
  static Widget defaultLeading(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final canPop = Navigator.of(context).canPop();
    if (!canPop) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.textColor),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final bool isLight = theme.isLight;

    // --- Compute effective visual properties ---

    final Color effectiveBgColor =
        backgroundColor ??
        (immersive
            ? (isLight
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFF1E1E1E).withValues(alpha: 0.1))
            : theme.surfaceColor);

    final double bottomBorderWidth = immersive ? 0.0 : 1.0;

    // --- Resolve leading widget ---

    final Widget effectiveLeading =
        leading ?? HosAppBar.defaultLeading(context);

    // --- Build the bar contents ---

    Widget bar = Container(
      height: height,
      padding: const EdgeInsets.only(left: 12, right: 16, top: 36),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: bottomBorderWidth > 0
            ? Border(
                bottom: BorderSide(
                  color: dividerColor ?? theme.dividerColor,
                  width: bottomBorderWidth,
                ),
              )
            : null,
      ),
      child: NavigationToolbar(
        leading: effectiveLeading,
        middle: title != null
            ? Text(
                title!,
                style: theme.typography.title2?.copyWith(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              )
            : null,
        trailing: actions != null
            ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
            : null,
      ),
    );

    // --- Wrap with BackdropFilter for the immersive frosted-glass effect ---

    if (immersive) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
          child: bar,
        ),
      );
    }

    return bar;
  }
}

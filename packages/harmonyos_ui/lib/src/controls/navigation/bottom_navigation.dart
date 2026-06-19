import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

/// A HarmonyOS-style bottom navigation item.
///
/// Each item consists of an icon and a label. Optionally provide a different
/// icon for the selected (active) state via [activeIcon].
///
/// Example:
/// ```dart
/// HosBottomNavItem(icon: Icons.home_outlined, label: '首页', activeIcon: Icons.home)
/// ```
class HosBottomNavItem {
  /// Creates a bottom navigation item.
  const HosBottomNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  /// The icon for the unselected state.
  final IconData icon;

  /// The label text. Recommended 2–4 Chinese characters or one English word.
  final String label;

  /// The icon for the selected state (optional, falls back to [icon]).
  final IconData? activeIcon;
}

/// HarmonyOS-style bottom navigation bar widget.
///
/// Implements the HarmonyOS Design System (HDS) bottom tab specifications:
/// - **Default height**: 56 vp, **icon size**: 24×24 vp
/// - **Immersive light effect** (沉浸光感): frosted glass via [BackdropFilter]
///   with a semi-transparent background — the HarmonyOS panel blur aesthetic.
/// - **Floating style**: rounded top corners, shadow, and horizontal margin
///   for a raised card appearance above the page content.
///
/// ## Standard usage (inside [Scaffold.bottomNavigationBar])
///
/// ```dart
/// HosBottomNavigation(
///   items: const [
///     HosBottomNavItem(icon: Icons.home, label: '首页'),
///     HosBottomNavItem(icon: Icons.settings, label: '设置'),
///   ],
///   selectedIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
/// )
/// ```
///
/// ## Floating / immersive usage (inside a [Stack])
///
/// ```dart
/// Stack(
///   children: [
///     // Page content — extends behind the bottom bar
///     ListView(children: [...]),
///     Positioned(
///       left: 0,
///       right: 0,
///       bottom: 0,
///       child: HosBottomNavigation(
///         items: const [...],
///         selectedIndex: _index,
///         onChanged: (i) => ...,
///         floating: true,     // rounded corners + shadow
///       ),
///     ),
///   ],
/// )
/// ```
///
/// ## Design tokens
///
/// | Property | Light mode | Dark mode |
/// |----------|-----------|-----------|
/// | Immersive mask | `Colors.white` @ 85 % opacity | `Color(0xFF1E1E1E)` @ 85 % |
/// | Active icon/text | `theme.accentColor.normal` | same |
/// | Inactive icon/text | `theme.textSecondaryColor` | same |
/// | Divider | 1 px `theme.dividerColor` | same |
/// | Floating shadow | 4 px blur, `theme.shadowColor` @ 20 % | same |
///
/// See the [HarmonyOS Design Guide](https://developer.huawei.com/consumer/cn/doc/design-guides/bottomtab-0000001956787789)
/// for the full specification.
class HosBottomNavigation extends StatefulWidget {
  /// Creates a HarmonyOS bottom navigation bar.
  const HosBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 56.0,
    this.iconSize = 24.0,
    this.immersive = true,
    this.blurSigmaX = 40.0,
    this.blurSigmaY = 40.0,
    this.floating = false,
    this.borderRadius,
    this.backgroundColor,
    this.dividerColor,
  });

  /// The navigation items. Recommended 3–5, at most 5.
  final List<HosBottomNavItem> items;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Called when an item is tapped.
  final ValueChanged<int> onChanged;

  /// Height of the bar. Defaults to 56 vp (HDS spec).
  final double height;

  /// Icon size in logical pixels. Defaults to 24 (HDS spec).
  final double iconSize;

  /// Whether to enable the immersive light effect (沉浸光感).
  ///
  /// When enabled, the bar renders with a [BackdropFilter] frosted-glass blur
  /// and a semi-transparent background, creating the HarmonyOS panel-blur
  /// aesthetic. This works best when content is visible *behind* the bar
  /// (e.g. inside a [Stack] or a page with translucent body background).
  ///
  /// Defaults to `true`.
  final bool immersive;

  /// Horizontal blur intensity for the immersive frosted-glass effect.
  ///
  /// Defaults to 40. Higher values produce a stronger blur.
  final double blurSigmaX;

  /// Vertical blur intensity for the immersive frosted-glass effect.
  ///
  /// Defaults to 40. Higher values produce a stronger blur.
  final double blurSigmaY;

  /// Whether to use a floating (raised card) style.
  ///
  /// When enabled the bar gains rounded top corners, a subtle shadow, and
  /// horizontal margin — ideal for overlaid navigation that sits above the
  /// page content. Implicitly enables [immersive].
  ///
  /// Defaults to `false`.
  final bool floating;

  /// Override for the container border radius.
  ///
  /// When [floating] is true the default is
  /// `BorderRadius.vertical(top: Radius.circular(20))`.
  final BorderRadius? borderRadius;

  /// Override for the bar background color.
  ///
  /// When not provided the immersive mode defaults to a semi-transparent
  /// white (light) or dark surface (dark); otherwise falls back to
  /// [HarmonyThemeData.surfaceColor].
  final Color? backgroundColor;

  /// Override for the top divider color.
  ///
  /// Defaults to [HarmonyThemeData.dividerColor]. The divider is not drawn
  /// when [floating] is true (rounded corners provide the visual boundary).
  final Color? dividerColor;

  @override
  State<HosBottomNavigation> createState() => _HosBottomNavigationState();
}

class _HosBottomNavigationState extends State<HosBottomNavigation> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HosBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    double offset = 0;
    for (int i = 0; i < widget.selectedIndex; i++) {
      offset += _estimateItemWidth(i) + 0; // no spacing between items
    }
    final double itemW = _estimateItemWidth(widget.selectedIndex);
    final double viewW = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    double target = offset - (viewW - itemW) / 2;
    target = target.clamp(0.0, maxScroll);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  double _estimateItemWidth(int index) {
    // icon area + label width + padding
    double w = widget.iconSize + 2 + 32; // padding horizontal 16 each side
    final double charW =
        (HarmonyTheme.maybeOf(context)?.typography.caption?.fontSize ?? 11) *
        0.6;
    w += widget.items[index].label.length * charW;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    // final theme = HarmonyTheme.of(context);
    // final bool isLight = theme.isLight;
    final bool useImmersive = widget.immersive || widget.floating;

    // --- Compute effective visual properties ---

    // final BorderRadius? effectiveRadius =
    //     widget.borderRadius ??
    //     (widget.floating
    //         ? BorderRadius.all(Radius.circular(widget.height / 2))
    //         : null);

    // final Color effectiveBgColor =
    //     widget.backgroundColor ??
    //     (useImmersive
    //         ? (isLight
    //               ? Colors.white.withValues(alpha: 0.70)
    //               : const Color(0xFF1E1E1E).withValues(alpha: 0.70))
    //         : theme.surfaceColor);

    // final double topBorderWidth = (!widget.floating && effectiveRadius == null)
    //     ? 1.0
    //     : 0.0;

    // --- Bar max width: screen width minus outer padding ---

    final double barMaxWidth =
        MediaQuery.of(context).size.width - (widget.floating ? 48.0 : 32.0);

    // --- Build the bar contents ---

    final Widget itemWidgets = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.items.length, (index) {
        final bool isSelected = index == widget.selectedIndex;
        final item = widget.items[index];
        return _HosBottomNavItemWidget(
          item: item,
          isSelected: isSelected,
          iconSize: widget.iconSize,
          onTap: () => widget.onChanged(index),
        );
      }),
    );

    Widget bar = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: barMaxWidth),
      child: widget.floating
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: itemWidgets,
              ),
            )
          : Container(
              padding: EdgeInsets.zero,
              height: widget.height,
              width: double.infinity,
              child: itemWidgets,
            ),
    );

    // --- Wrap with BackdropFilter for the immersive frosted-glass effect ---
    if (useImmersive) {
      bar = HarmonyGlowMaterial(
        materialLevel: HarmonyGlowMaterialLevel.smooth,
        borderRadius: widget.floating
            ? BorderRadius.circular(32)
            : BorderRadius.vertical(top: Radius.circular(0)),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: !widget.floating ? MediaQuery.paddingOf(context).bottom : 0,
          ),
          child: widget.floating ? bar : Center(child: bar),
        ),
      );
    }

    if (!widget.floating) {
      return bar;
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16).add(
          EdgeInsets.only(
            bottom: widget.floating ? MediaQuery.paddingOf(context).bottom : 0,
            left: 24,
            right: 24,
          ),
        ),
        child: bar,
      ),
    );
  }
}

/// Internal widget for a single bottom navigation item.
///
/// Renders an icon + label column with:
/// - Animated colour transitions between selected and unselected states.
/// - A HarmonyOS-style press ripple (光晕) on tap via [InkWell].
class _HosBottomNavItemWidget extends StatelessWidget {
  const _HosBottomNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.onTap,
  });

  final HosBottomNavItem item;
  final bool isSelected;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        // borderRadius: BorderRadius.circular(12),
        // splashColor: theme.accentColor.normal.withValues(alpha: 0),

        // splashColor: theme.accentColor.normal.withValues(alpha: 0.12),
        //  / highlightColor: theme.accentColor.normal.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: theme.animationDuration,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(minWidth: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Icon(
                isSelected && item.activeIcon != null
                    ? item.activeIcon
                    : item.icon,
                size: iconSize,
                color: isSelected ? theme.accentColor.normal : theme.textColor,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: theme.typography.caption?.copyWith(
                  color: isSelected
                      ? theme.accentColor.normal
                      : theme.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:harmonyos_ui/src/widgets/custome_scroll_behavior.dart'
    show CustomScrollBehaviour;

import '../../styles/theme.dart';

/// A HarmonyOS ChipsGroup-style tab bar.
///
/// Follows the [HarmonyOS NEXT ChipsGroup Design Guide](https://developer.huawei.com/consumer/cn/doc/design-guides/chipsgroup-0000001929788350):
/// each tab is rendered as a rounded pill (capsule) chip.
///
/// Chips are always content-sized. When their total width exceeds the
/// available space the row scrolls horizontally via [SingleChildScrollView]
/// with [BouncingScrollPhysics].
///
/// - **Selected chip**: filled accent color background with white text.
/// - **Unselected chip**: transparent background with an optional subtle
///   outline and secondary text color.
/// - **Animation**: smooth background and border colour transitions via
///   [AnimatedContainer] (duration / curve from [HarmonyThemeData]).
/// - **Auto-scroll**: the selected chip is scrolled into view when
///   [selectedIndex] changes.
///
/// Example:
/// ```dart
/// HosTabBar(
///   tabs: ['Tab 1', 'Tab 2', 'Tab 3'],
///   selectedIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
/// )
/// ```
///
/// With icons:
/// ```dart
/// HosTabBar(
///   tabs: ['Home', 'Settings'],
///   icons: [Icons.home, Icons.settings],
///   selectedIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
/// )
/// ```
///
/// ## Design tokens
///
/// | Property          | Value                            |
/// |-------------------|----------------------------------|
/// | Chip height       | 36 vp (customisable)             |
/// | Chip spacing      | 8 vp between chips               |
/// | Chip padding      | horizontal 16 vp, vertical 8 vp  |
/// | Border radius     | 18 vp (half height = full pill)  |
/// | Font              | `theme.typography.body` (14 px)  |
/// | Selected bg       | `theme.accentColor.normal`       |
/// | Selected text     | `Colors.white`                   |
/// | Unselected bg     | transparent                      |
/// | Unselected border | `theme.dividerColor` (optional)  |
/// | Unselected text   | `theme.textSecondaryColor`       |
class HosTabBar extends StatefulWidget {
  /// Creates a HarmonyOS ChipsGroup tab bar.
  const HosTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.chipHeight = 36.0,
    this.chipSpacing = 8.0,
    this.chipPadding,
    this.showOutline = true,
    this.icons,
  });

  /// The tab labels.
  final List<String> tabs;

  /// The index of the currently selected tab.
  final int selectedIndex;

  /// Called when a tab is tapped.
  final ValueChanged<int> onChanged;

  /// Height of each chip in logical pixels.
  ///
  /// Defaults to 36 vp per the HDS ChipsGroup spec.
  final double chipHeight;

  /// Horizontal gap between adjacent chips.
  ///
  /// Defaults to 8 vp per the HDS ChipsGroup spec.
  final double chipSpacing;

  /// Padding inside each chip.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`.
  final EdgeInsetsGeometry? chipPadding;

  /// Whether unselected chips display a subtle outline border.
  ///
  /// When `true` (default) unselected chips render with a 1 px border in
  /// [HarmonyThemeData.dividerColor]. Set to `false` for a cleaner look
  /// where only the selected chip has visual weight.
  final bool showOutline;

  /// Optional icons for each tab. Must match [tabs] length.
  ///
  /// When provided an [Icon] is placed before each label inside the chip.
  final List<IconData>? icons;

  @override
  State<HosTabBar> createState() => _HosTabBarState();
}

class _HosTabBarState extends State<HosTabBar> {
  final ScrollController _scrollController = ScrollController();

  EdgeInsets get _effectivePadding {
    final p = widget.chipPadding;
    if (p == null) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
    return p.resolve(Directionality.of(context));
  }

  double get _borderRadius => widget.chipHeight / 2;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HosTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  /// Scrolls so that the selected chip is visible in the viewport.
  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    final ep = _effectivePadding;
    double offset = 0.0;
    for (int i = 0; i < widget.selectedIndex; i++) {
      offset += _estimateChipWidth(i, ep) + widget.chipSpacing;
    }

    final double chipW = _estimateChipWidth(widget.selectedIndex, ep);
    final double viewW = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;

    double target = offset - (viewW - chipW) / 2;
    target = target.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// Rough chip width estimate for scroll positioning.
  double _estimateChipWidth(int index, EdgeInsets ep) {
    double w = ep.left + ep.right;
    if (widget.icons != null && index < widget.icons!.length) {
      w += _iconSize + 4;
    }
    final double fs =
        HarmonyTheme.maybeOf(context)?.typography.body?.fontSize ?? 14;
    w += widget.tabs[index].length * fs * 0.6;
    return w;
  }

  double get _iconSize =>
      HarmonyTheme.maybeOf(context)?.typography.body?.fontSize ?? 14;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final ep = _effectivePadding;

    return SizedBox(
      height: widget.chipHeight + ep.top + ep.bottom,
      width: double.infinity,
      // color: theme.surfaceColor,
      child: ScrollConfiguration(
        behavior: CustomScrollBehaviour(),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          // physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: ep.left),
          child: Row(
            children: List.generate(widget.tabs.length, (index) {
              final bool isSelected = index == widget.selectedIndex;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.tabs.length - 1
                      ? widget.chipSpacing
                      : 0,
                ),
                child: _HosTabChip(
                  label: widget.tabs[index],
                  icon: widget.icons != null && index < widget.icons!.length
                      ? widget.icons![index]
                      : null,
                  isSelected: isSelected,
                  chipHeight: widget.chipHeight,
                  chipPadding: ep,
                  borderRadius: _borderRadius,
                  showOutline: widget.showOutline,
                  theme: theme,
                  onTap: () => widget.onChanged(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// A single chip inside a [HosTabBar].
///
/// Renders a rounded pill with:
/// - Filled accent background + white text when selected
/// - Transparent background + subtle outline + secondary text when unselected
/// - Smooth [AnimatedContainer] transitions between states
class _HosTabChip extends StatelessWidget {
  const _HosTabChip({
    required this.label,
    required this.isSelected,
    required this.chipHeight,
    required this.chipPadding,
    required this.borderRadius,
    required this.showOutline,
    required this.theme,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final double chipHeight;
  final EdgeInsetsGeometry chipPadding;
  final double borderRadius;
  final bool showOutline;
  final HarmonyThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: theme.animationDuration,
        curve: theme.animationCurve,
        height: chipHeight,
        padding: chipPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.normal : theme.surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: _resolveBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: _iconSize,
                color: isSelected ? Colors.white : theme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (theme.typography.body ?? const TextStyle()).copyWith(
                height: 1.0,
                color: isSelected ? Colors.white : theme.textColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Border? _resolveBorder() {
    if (isSelected) return null;
    if (!showOutline) return null;
    return Border.all(color: theme.dividerColor, width: 1.0);
  }

  /// Icon size — matches body font size for inline alignment with text.
  double get _iconSize => theme.typography.body?.fontSize ?? 14;
}

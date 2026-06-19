import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style navigation rail.
///
/// A vertical sidebar navigation typically used on tablets and desktop
/// layouts. Displays icon + label items with accent color highlights.
///
/// Example:
/// ```dart
/// HosNavigationRail(
///   items: [
///     HosNavRailItem(icon: Icons.home, label: 'Home'),
///     HosNavRailItem(icon: Icons.settings, label: 'Settings'),
///   ],
///   selectedIndex: _index,
///   onChanged: (i) => setState(() => _index = i),
/// )
/// ```
class HosNavRailItem {
  /// Creates a navigation rail item.
  const HosNavRailItem({
    required this.icon,
    required this.label,
  });

  /// The icon.
  final IconData icon;

  /// The label text.
  final String label;
}

/// HarmonyOS-style navigation rail widget.
class HosNavigationRail extends StatefulWidget {
  /// Creates a HarmonyOS navigation rail.
  const HosNavigationRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.width = 72,
    this.header,
    this.footer,
  });

  /// The navigation items.
  final List<HosNavRailItem> items;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Called when an item is tapped.
  final ValueChanged<int> onChanged;

  /// Width of the rail.
  final double width;

  /// Optional widget at the top.
  final Widget? header;

  /// Optional widget at the bottom.
  final Widget? footer;

  @override
  State<HosNavigationRail> createState() => _HosNavigationRailState();
}

class _HosNavigationRailState extends State<HosNavigationRail> {
  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          right: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          if (widget.header != null) widget.header!,
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: List.generate(widget.items.length, (index) {
                final bool isSelected = index == widget.selectedIndex;
                final item = widget.items[index];

                return GestureDetector(
                  onTap: () => widget.onChanged(index),
                  child: AnimatedContainer(
                    duration: theme.animationDuration,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: theme.accentColor.normal
                                .withValues(alpha: 0.1),
                            border: Border(
                              left: BorderSide(
                                color: theme.accentColor.normal,
                                width: 3,
                              ),
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? theme.accentColor.normal
                              : theme.textSecondaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: theme.typography.caption?.copyWith(
                            color: isSelected
                                ? theme.accentColor.normal
                                : theme.textSecondaryColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
    );
  }
}

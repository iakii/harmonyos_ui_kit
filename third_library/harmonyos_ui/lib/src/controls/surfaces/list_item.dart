import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style list item (list tile).
///
/// A row with optional leading widget (icon/avatar), title, subtitle,
/// and trailing widget. Supports tap interaction with ripple feedback.
///
/// Example:
/// ```dart
/// HosListItem(
///   leading: Icon(Icons.person),
///   title: 'John Doe',
///   subtitle: 'Online',
///   trailing: Icon(Icons.chevron_right),
///   onTap: () => print('Tapped'),
/// )
/// ```
class HosListItem extends StatelessWidget {
  /// Creates a HarmonyOS list item.
  const HosListItem({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.height = 56,
  });

  /// Widget at the start of the row.
  final Widget? leading;

  /// Primary text.
  final String? title;

  /// Secondary text below the title.
  final String? subtitle;

  /// Widget at the end of the row.
  final Widget? trailing;

  /// Called when tapped.
  final VoidCallback? onTap;

  /// Padding override.
  final EdgeInsetsGeometry? padding;

  /// Height of the item.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: theme.typography.body?.copyWith(
                        color: theme.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.typography.bodySmall?.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

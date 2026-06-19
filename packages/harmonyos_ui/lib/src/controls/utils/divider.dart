import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style horizontal divider.
///
/// A thin line separator with optional label text in the center.
/// Uses the theme's divider color.
///
/// Example:
/// ```dart
/// // Simple divider
/// HosDivider()
///
/// // Divider with label
/// HosDivider(label: 'OR')
/// ```
class HosDivider extends StatelessWidget {
  /// Creates a HarmonyOS divider.
  const HosDivider({
    super.key,
    this.label,
    this.indent,
    this.endIndent,
    this.thickness,
    this.color,
  });

  /// Optional label text displayed in the center.
  final String? label;

  /// Space before the divider line.
  final double? indent;

  /// Space after the divider line.
  final double? endIndent;

  /// Thickness of the divider line.
  final double? thickness;

  /// Color override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    if (label != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _buildLine(theme),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label!,
                style: theme.typography.bodySmall?.copyWith(
                  color: theme.textSecondaryColor,
                ),
              ),
            ),
            Expanded(
              child: _buildLine(theme),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: indent ?? 0,
        right: endIndent ?? 0,
      ),
      child: _buildLine(theme),
    );
  }

  Widget _buildLine(HarmonyThemeData theme) {
    return Divider(
      height: 1,
      thickness: thickness ?? 0.5,
      color: color ?? theme.dividerColor,
    );
  }
}

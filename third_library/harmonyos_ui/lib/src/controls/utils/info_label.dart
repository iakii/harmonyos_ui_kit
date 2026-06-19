import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style info label with optional tooltip.
///
/// Displays a label with an info icon that shows additional information
/// in a tooltip on hover or tap. Commonly used in settings pages and
/// form sections.
///
/// Example:
/// ```dart
/// HosInfoLabel(
///   label: 'Dark mode',
///   info: 'Enable dark mode to reduce eye strain in low light.',
///   child: HosSwitch(checked: isDark, onChanged: (v) => ...),
/// )
/// ```
class HosInfoLabel extends StatelessWidget {
  /// Creates a HarmonyOS info label.
  const HosInfoLabel({
    super.key,
    required this.label,
    this.info,
    this.child,
    this.labelStyle,
  });

  /// The primary label text.
  final String label;

  /// Optional info tooltip text.
  final String? info;

  /// Optional trailing widget (e.g. a switch or checkbox).
  final Widget? child;

  /// Label text style override.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: labelStyle ??
                        theme.typography.body?.copyWith(
                          color: theme.textColor,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (info != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: info!,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

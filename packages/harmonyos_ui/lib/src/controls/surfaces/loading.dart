import 'package:flutter/material.dart';

import '../../styles/theme.dart';
import 'progress.dart';

/// A HarmonyOS-style loading overlay or inline widget.
///
/// Displays a centered [HosProgressRing] with an optional message.
/// Can be used as an overlay or as an inline loading indicator.
///
/// Example:
/// ```dart
/// // Inline
/// HosLoading(message: 'Loading...')
///
/// // Overlay
/// HosLoading.show(context);
/// ```
class HosLoading extends StatelessWidget {
  /// Creates a HarmonyOS loading widget.
  const HosLoading({
    super.key,
    this.message,
    this.size = 32,
  });

  /// Optional message below the spinner.
  final String? message;

  /// Size of the spinner.
  final double size;

  /// Shows a loading overlay and returns a function to dismiss it.
  static VoidCallback show(
    BuildContext context, {
    String? message,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black26,
        child: Center(
          child: HosLoading(message: message),
        ),
      ),
    );
    overlay.insert(entry);
    return () => entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HosProgressRing(size: size),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.typography.body?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

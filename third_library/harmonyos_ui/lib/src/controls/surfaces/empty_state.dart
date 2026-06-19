import 'package:flutter/material.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';

/// A HarmonyOS-style empty state placeholder.
///
/// Displays an icon, title, and optional message to indicate that a
/// view has no content. Useful for empty lists, search results, etc.
///
/// Example:
/// ```dart
/// HosEmptyState(
///   icon: Icons.inbox,
///   title: 'No messages',
///   message: 'Your inbox is empty',
/// )
/// ```
class HosEmptyState extends StatelessWidget {
  /// Creates a HarmonyOS empty state widget.
  const HosEmptyState({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.action,
    this.iconSize = 56,
  });

  /// The icon to display.
  final IconData? icon;

  /// The title text.
  final String? title;

  /// Optional descriptive message.
  final String? message;

  /// Optional action button.
  final Widget? action;

  /// Size of the icon.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: iconSize,
                color: theme.disabledColor,
              ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: theme.typography.title3?.copyWith(
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.typography.bodySmall?.copyWith(
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A HarmonyOS-style error state placeholder.
///
/// Similar to [HosEmptyState] but styled for error scenarios with a
/// red-tinted icon and a retry action.
///
/// Example:
/// ```dart
/// HosErrorState(
///   message: 'Failed to load data',
///   onRetry: () => reload(),
/// )
/// ```
class HosErrorState extends StatelessWidget {
  /// Creates a HarmonyOS error state widget.
  const HosErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.iconSize = 56,
  });

  /// The title text.
  final String? title;

  /// Optional descriptive message.
  final String? message;

  /// Called when the user taps retry.
  final VoidCallback? onRetry;

  /// Size of the error icon.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: iconSize,
              color: HarmonyColors.errorColor.withValues(alpha: 0.7),
            ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: theme.typography.title3?.copyWith(
                  color: theme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: theme.typography.bodySmall?.copyWith(
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: theme.accentColor.normal, width: 1),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: theme.typography.title3?.copyWith(
                      color: theme.accentColor.normal,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

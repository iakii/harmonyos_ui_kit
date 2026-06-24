import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style dialog.
///
/// A rounded modal dialog with title, content, and action buttons.
/// The theme accent color is used for the primary action button.
///
/// Example:
/// ```dart
/// final result = await showHosDialog(
///   context: context,
///   title: 'Confirm',
///   content: 'Are you sure?',
///   actions: [
///     HosDialogButton('Cancel', onTap: () => Navigator.pop(context, false)),
///     HosDialogButton('OK', isPrimary: true, onTap: () => Navigator.pop(context, true)),
///   ],
/// );
/// ```
Future<T?> showHosDialog<T>({
  required BuildContext context,
  String? title,
  String? content,
  Widget? contentWidget,
  List<Widget>? actions,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final theme = HarmonyTheme.of(context);

  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    builder: (context) => Dialog(
      backgroundColor: theme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  title,
                  style: theme.typography.title2?.copyWith(color: theme.textColor),
                ),
              ),
            if (contentWidget != null)
              contentWidget
            else if (content != null)
              Text(
                content,
                style: theme.typography.body?.copyWith(color: theme.textSecondaryColor),
              ),
            if (actions != null && actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// A button used inside [showHosDialog] actions.
class HosDialogButton extends StatelessWidget {
  /// Creates a dialog action button.
  const HosDialogButton(
    this.label, {
    super.key,
    this.onTap,
    this.isPrimary = false,
  });

  /// The button label.
  final String label;

  /// Called when tapped.
  final VoidCallback? onTap;

  /// Whether this is the primary action (uses accent color).
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isPrimary
              ? ShapeDecoration(
                  color: theme.accentColor.normal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              : null,
          child: Text(
            label,
            style: theme.typography.title3?.copyWith(
              color: isPrimary ? Colors.white : theme.accentColor.normal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

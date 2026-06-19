import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style bottom sheet.
///
/// Slides up from the bottom of the screen with a drag handle at the
/// top. Content is scrollable and can be dismissed by swiping down
/// or tapping the backdrop.
///
/// Example:
/// ```dart
/// showHosBottomSheet(
///   context: context,
///   builder: (context) => Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Bottom sheet content'),
///   ),
/// );
/// ```
Future<T?> showHosBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool showDragHandle = true,
  bool isScrollControlled = false,
  bool isDismissible = true,
}) {
  final theme = HarmonyTheme.of(context);

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    backgroundColor: theme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: ShapeDecoration(
                    color: theme.dividerColor,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  title,
                  style: theme.typography.title2?.copyWith(color: theme.textColor),
                ),
              ),
            Flexible(child: builder(context)),
          ],
        ),
      );
    },
  );
}

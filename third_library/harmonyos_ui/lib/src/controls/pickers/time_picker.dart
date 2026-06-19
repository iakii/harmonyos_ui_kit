import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style time picker dialog.
///
/// Displays a clock-based time picker with HDS styling and
/// hour/minute selection. Uses the theme's accent color.
///
/// Example:
/// ```dart
/// final time = await showHosTimePicker(
///   context: context,
///   initialTime: TimeOfDay.now(),
/// );
/// ```
Future<TimeOfDay?> showHosTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  final theme = HarmonyTheme.of(context);

  final result = await showTimePicker(
    context: context,
    initialTime: initialTime,
    helpText: helpText,
    cancelText: cancelText,
    confirmText: confirmText,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: theme.accentColor.normal,
            brightness: theme.brightness,
          ),
          dialogTheme: DialogThemeData(backgroundColor: theme.surfaceColor),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: theme.surfaceColor,
            hourMinuteTextColor: theme.textColor,
            hourMinuteColor: theme.backgroundColor,
            dayPeriodTextColor: theme.textColor,
            dayPeriodColor: theme.backgroundColor,
            dialHandColor: theme.accentColor.normal,
            dialBackgroundColor: theme.backgroundColor,
            dialTextColor: theme.textColor,
            entryModeIconColor: theme.accentColor.normal,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: theme.accentColor.normal,
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  return result;
}

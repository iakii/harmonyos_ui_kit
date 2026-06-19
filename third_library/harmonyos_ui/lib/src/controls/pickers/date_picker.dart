import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style date picker dialog.
///
/// Displays a calendar-based date picker with HDS styling and
/// year/month selection. Uses the theme's accent color for the
/// selected date highlight.
///
/// Example:
/// ```dart
/// final date = await showHosDatePicker(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2020),
///   lastDate: DateTime(2030),
/// );
/// ```
Future<DateTime?> showHosDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerMode initialMode = DatePickerMode.day,
  String? helpText,
  String? cancelText,
  String? confirmText,
}) async {
  final theme = HarmonyTheme.of(context);

  final result = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDatePickerMode: initialMode,
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

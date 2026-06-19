import 'package:flutter/widgets.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';
import '../../utils.dart';
import 'base.dart';
import 'theme.dart';

// --------------------------------------------------------------------
// HosOutlinedButton — Secondary / outlined button
// --------------------------------------------------------------------

/// A HarmonyOS-style outlined (secondary) button.
///
/// The outlined button has a transparent background with a border stroke
/// in the accent color. It is less visually prominent than [HosButton]
/// and is typically used for secondary actions.
///
/// Example:
/// ```dart
/// HosOutlinedButton(
///   onPressed: () { ... },
///   child: Text('Cancel'),
/// )
/// ```
class HosOutlinedButton extends HosBaseButton {
  /// Creates an outlined secondary button.
  const HosOutlinedButton({
    super.key,
    required super.child,
    required super.onPressed,
    super.onLongPress,
    super.onHover,
    super.onFocusChange,
    super.style,
    super.focusNode,
    super.autofocus,
    super.semanticLabel,
    super.enabled,
  });

  @override
  HosButtonStyle defaultStyleOf(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final accent = theme.accentColor;

    return HosButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isPressed) {
          return accent.normal.withValues(alpha: 0.1);
        }
        if (states.isHovered) {
          return accent.normal.withValues(alpha: 0.05);
        }
        return HarmonyColors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return theme.disabledColor;
        return accent.normal;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) {
          return BorderSide(color: theme.disabledColor);
        }
        return BorderSide(color: accent.normal, width: 1.0);
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(64, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.typography.title3,
      ),
    );
  }

  @override
  HosButtonStyle? themeStyleOf(BuildContext context) {
    return HosButtonTheme.of(context)?.outlinedButtonStyle;
  }
}

import 'package:flutter/widgets.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';
import '../../utils.dart';
import 'base.dart';
import 'theme.dart';

// --------------------------------------------------------------------
// HosButton — Primary / filled button
// --------------------------------------------------------------------

/// A HarmonyOS-style primary (filled) button.
///
/// The filled button is the most visually prominent button variant,
/// using the theme's [HosAccentColor.normal] as background and white
/// as foreground text.
///
/// Example:
/// ```dart
/// HosButton(
///   onPressed: () { ... },
///   child: Text('Submit'),
/// )
/// ```
class HosButton extends HosBaseButton {
  /// Creates a primary filled button.
  const HosButton({
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
        if (states.isDisabled) return theme.disabledColor;
        if (states.isPressed) return accent.dark;
        if (states.isHovered) return accent.light;
        return accent.normal;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) {
          return theme.textSecondaryColor;
        }
        return accent.normal.basedOnLuminance();
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.isHovered) {
          return HarmonyColors.white.withValues(alpha: 0.1);
        }
        if (states.isPressed) {
          return HarmonyColors.black.withValues(alpha: 0.1);
        }
        return HarmonyColors.transparent;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.isPressed) return 0.0;
        return 1.0;
      }),
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
    return HosButtonTheme.of(context)?.filledButtonStyle;
  }
}

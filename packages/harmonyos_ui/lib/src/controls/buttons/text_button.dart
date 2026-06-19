import 'package:flutter/widgets.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';
import '../../utils.dart';
import 'base.dart';
import 'theme.dart';

// --------------------------------------------------------------------
// HosTextButton — Ghost / text-only button
// --------------------------------------------------------------------

/// A HarmonyOS-style text button (ghost button).
///
/// The text button has no border or background fill — only text/icon in
/// the accent color. It is the least visually prominent button variant
/// and is typically used for inline or tertiary actions.
///
/// On hover, a subtle background tint appears.
///
/// Example:
/// ```dart
/// HosTextButton(
///   onPressed: () { ... },
///   child: Text('Learn more'),
/// )
/// ```
class HosTextButton extends HosBaseButton {
  /// Creates a text-only ghost button.
  const HosTextButton({
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
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(48, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        theme.typography.title3,
      ),
    );
  }

  @override
  HosButtonStyle? themeStyleOf(BuildContext context) {
    return HosButtonTheme.of(context)?.textButtonStyle;
  }
}

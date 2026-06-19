import 'package:flutter/widgets.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';
import '../../utils.dart';
import 'base.dart';
import 'theme.dart';

// --------------------------------------------------------------------
// HosIconButton — Icon-only button
// --------------------------------------------------------------------

/// A HarmonyOS-style icon button.
///
/// A compact, square button displaying only an icon. Commonly used in
/// toolbars, app bars, and inline actions. On hover a circular tint
/// appears behind the icon.
///
/// Example:
/// ```dart
/// HosIconButton(
///   onPressed: () { ... },
///   child: Icon(Icons.settings),
/// )
/// ```
class HosIconButton extends HosBaseButton {
  /// Creates an icon-only button.
  const HosIconButton({
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
          return accent.normal.withValues(alpha: 0.15);
        }
        if (states.isHovered) {
          return accent.normal.withValues(alpha: 0.08);
        }
        return HarmonyColors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.isDisabled) return theme.disabledColor;
        return theme.textColor;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(36, 36)),
      fixedSize: const WidgetStatePropertyAll(Size(36, 36)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
      iconSize: 20,
    );
  }

  @override
  HosButtonStyle? themeStyleOf(BuildContext context) {
    return HosButtonTheme.of(context)?.iconButtonStyle;
  }
}

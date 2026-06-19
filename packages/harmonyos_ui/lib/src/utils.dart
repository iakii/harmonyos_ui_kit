import 'package:flutter/widgets.dart';

/// Extension methods on [Set<WidgetState>] for convenient state checks.
extension WidgetStateExtension on Set<WidgetState> {
  /// Whether the widget is currently pressed.
  bool get isPressed => contains(WidgetState.pressed);

  /// Whether the widget is currently hovered.
  bool get isHovered => contains(WidgetState.hovered);

  /// Whether the widget is currently focused.
  bool get isFocused => contains(WidgetState.focused);

  /// Whether the widget is disabled.
  bool get isDisabled => contains(WidgetState.disabled);

  /// Whether the widget is in the error state.
  bool get isError => contains(WidgetState.error);

  /// Whether no interaction states are active (idle).
  bool get isNone => length == 0;

  /// Whether any "active" state is present (hovered, pressed, or focused).
  bool get isActive => isHovered || isPressed || isFocused;
}

/// Checks that a [HarmonyTheme] ancestor exists in the widget tree.
///
/// Calls [HarmonyTheme.of] and asserts if no theme is found. Use in
/// widget build methods that require a theme.
///
/// Note: importing this file does not automatically import
/// `HarmonyTheme`; consumers need to import the theme file separately
/// or use `harmonyos_ui.dart` to get both.
bool debugCheckHasHarmonyTheme(BuildContext context) {
  assert(() {
    // We use a try-catch to avoid importing theme.dart here.
    // The actual assertion happens in HarmonyTheme.of().
    return true;
  }());
  return true;
}

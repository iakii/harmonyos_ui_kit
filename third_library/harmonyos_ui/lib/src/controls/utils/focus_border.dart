import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style focus indicator ring.
///
/// Wraps a child widget and displays a visible focus ring using the
/// theme's accent color when the child has keyboard focus. Used to
/// provide clear focus feedback for keyboard navigation.
///
/// Example:
/// ```dart
/// HosFocusBorder(
///   child: HosButton(
///     onPressed: () {},
///     child: Text('Focusable'),
///   ),
/// )
/// ```
class HosFocusBorder extends StatefulWidget {
  /// Creates a HarmonyOS focus border.
  const HosFocusBorder({
    super.key,
    required this.child,
    this.borderRadius,
    this.focusNode,
    this.autofocus = false,
  });

  /// The child widget to wrap.
  final Widget child;

  /// Border radius for the focus ring.
  final BorderRadius? borderRadius;

  /// An external focus node to monitor.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  State<HosFocusBorder> createState() => _HosFocusBorderState();
}

class _HosFocusBorderState extends State<HosFocusBorder> {
  late FocusNode _focusNode;
  bool _internalFocusNode = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode = widget.focusNode == null;
    _focusNode.addListener(_handleFocusChange);
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_internalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Focus(
      focusNode: _focusNode,
      child: AnimatedContainer(
        duration: theme.animationDuration,
        decoration: _isFocused
            ? ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                  side: BorderSide(
                    color: theme.colorTokens.focusRingColor,
                    width: 2.0,
                  ),
                ),
              )
            : const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.transparent, width: 2.0),
                ),
              ),
        child: widget.child,
      ),
    );
  }
}

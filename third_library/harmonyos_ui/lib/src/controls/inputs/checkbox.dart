import 'package:flutter/material.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';

/// A HarmonyOS-style checkbox.
///
/// An animated checkbox with rounded corners that fills with the accent
/// color when checked. Supports tristate mode.
///
/// Example:
/// ```dart
/// HosCheckbox(
///   checked: isChecked,
///   onChanged: (value) => setState(() => isChecked = value),
/// )
/// ```
class HosCheckbox extends StatefulWidget {
  /// Creates a HarmonyOS checkbox.
  const HosCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.tristate = false,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  /// Whether the checkbox is checked.
  final bool checked;

  /// Called when the checkbox is tapped.
  final ValueChanged<bool>? onChanged;

  /// Whether to use tristate mode (checked / indeterminate / unchecked).
  final bool tristate;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _isInteractive => onChanged != null;

  @override
  State<HosCheckbox> createState() => _HosCheckboxState();
}

class _HosCheckboxState extends State<HosCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _hovering = false;
  bool _pressing = false;
  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.checked) {
      _controller.value = 1.0;
    }
    _focusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode = widget.focusNode == null;
  }

  @override
  void dispose() {
    if (_internalFocusNode) _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HosCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked) {
      if (widget.checked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final accent = theme.accentColor;
    final isDark = theme.brightness == Brightness.dark;
    final isChecked = widget.checked;
    final isInteractive = widget._isInteractive;

    // Resolve colors by state
    final Color fillColor;
    final Color borderColor;
    final Color checkColor;

    if (!isInteractive) {
      fillColor = isChecked ? theme.disabledColor : HarmonyColors.transparent;
      borderColor = theme.disabledColor;
      checkColor = isDark ? const Color(0xFF1E1E1E) : HarmonyColors.white;
    } else if (_pressing) {
      fillColor = isChecked
          ? accent.dark
          : accent.normal.withValues(alpha: 0.1);
      borderColor = accent.dark;
      checkColor = HarmonyColors.white;
    } else if (_hovering) {
      fillColor = isChecked
          ? accent.light
          : accent.normal.withValues(alpha: 0.05);
      borderColor = accent.light;
      checkColor = HarmonyColors.white;
    } else if (isChecked) {
      fillColor = accent.normal;
      borderColor = accent.normal;
      checkColor = HarmonyColors.white;
    } else {
      fillColor = HarmonyColors.transparent;
      borderColor = isDark
          ? const Color(0xFF808080)
          : const Color(0xFFBFBFBF);
      checkColor = HarmonyColors.white;
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: GestureDetector(
        onTapDown:
            isInteractive ? (_) => setState(() => _pressing = true) : null,
        onTapUp: isInteractive
            ? (_) {
                setState(() => _pressing = false);
                widget.onChanged!(!widget.checked);
              }
            : null,
        onTapCancel:
            isInteractive ? () => setState(() => _pressing = false) : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Semantics(
            checked: isChecked,
            label: widget.semanticLabel,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pressing ? _scaleAnim.value : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    width: 20,
                    height: 20,
                    decoration: ShapeDecoration(
                      color: fillColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: borderColor, width: 1.5),
                      ),
                    ),
                    child: isChecked
                        ? Icon(Icons.check, size: 14, color: checkColor)
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';

/// A HarmonyOS-style radio button.
///
/// A circular selection control that fills with the accent color when
/// selected. Radio buttons are typically used in mutually exclusive
/// groups.
///
/// Example:
/// ```dart
/// HosRadio(
///   selected: _value == 1,
///   onChanged: () => setState(() => _value = 1),
/// )
/// ```
class HosRadio extends StatefulWidget {
  /// Creates a HarmonyOS radio button.
  const HosRadio({
    super.key,
    required this.selected,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  /// Whether this radio is selected.
  final bool selected;

  /// Called when the radio is tapped.
  final VoidCallback? onChanged;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _isInteractive => onChanged != null;

  @override
  State<HosRadio> createState() => _HosRadioState();
}

class _HosRadioState extends State<HosRadio>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
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
    if (widget.selected) {
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
  void didUpdateWidget(HosRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
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
    final isInteractive = widget._isInteractive;

    final Color outerBorderColor;
    final Color innerColor;

    if (!isInteractive) {
      outerBorderColor = theme.disabledColor;
      innerColor = widget.selected ? theme.disabledColor : HarmonyColors.transparent;
    } else if (_pressing) {
      outerBorderColor = accent.dark;
      innerColor = accent.dark;
    } else if (_hovering) {
      outerBorderColor = accent.light;
      innerColor = widget.selected ? accent.light : HarmonyColors.transparent;
    } else if (widget.selected) {
      outerBorderColor = accent.normal;
      innerColor = accent.normal;
    } else {
      outerBorderColor =
          isDark ? const Color(0xFF808080) : const Color(0xFFBFBFBF);
      innerColor = HarmonyColors.transparent;
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
                widget.onChanged!();
              }
            : null,
        onTapCancel:
            isInteractive ? () => setState(() => _pressing = false) : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Semantics(
            selected: widget.selected,
            label: widget.semanticLabel,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: ShapeDecoration(
                    shape: CircleBorder(
                      side: BorderSide(color: outerBorderColor, width: 1.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: ShapeDecoration(
                        color: innerColor,
                        shape: const CircleBorder(),
                      ),
                    ),
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

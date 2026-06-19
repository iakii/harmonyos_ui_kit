import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style toggle switch.
///
/// A pill-shaped toggle with smooth sliding animation. Uses the accent
/// color for the "on" state and a neutral grey for the "off" state.
///
/// Example:
/// ```dart
/// HosSwitch(
///   checked: isOn,
///   onChanged: (value) => setState(() => isOn = value),
/// )
/// ```
class HosSwitch extends StatefulWidget {
  /// Creates a HarmonyOS toggle switch.
  const HosSwitch({
    super.key,
    required this.checked,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  /// Whether the switch is on.
  final bool checked;

  /// Called when the switch is toggled.
  final ValueChanged<bool>? onChanged;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _isInteractive => onChanged != null;

  @override
  State<HosSwitch> createState() => _HosSwitchState();
}

class _HosSwitchState extends State<HosSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbPosition;
  bool _hovering = false;
  bool _pressing = false;
  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  // Layout constants
  static const double _trackWidth = 44;
  static const double _trackHeight = 24;
  static const double _thumbSize = 20;
  static const double _thumbPadding = 2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _thumbPosition = Tween<double>(
      begin: _thumbPadding,
      end: _trackWidth - _thumbSize - _thumbPadding,
    ).animate(
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
  void didUpdateWidget(HosSwitch oldWidget) {
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
    final isInteractive = widget._isInteractive;

    final Color trackColor;

    if (!isInteractive) {
      trackColor = theme.disabledColor;
    } else if (_pressing) {
      trackColor = widget.checked
          ? accent.dark
          : (isDark ? const Color(0xFF595959) : const Color(0xFFBFBFBF));
    } else if (_hovering) {
      trackColor = widget.checked
          ? accent.light
          : (isDark ? const Color(0xFF4D4D4D) : const Color(0xFFD9D9D9));
    } else if (widget.checked) {
      trackColor = accent.normal;
    } else {
      trackColor =
          isDark ? const Color(0xFF404040) : const Color(0xFFD9D9D9);
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: GestureDetector(
        onTap:
            isInteractive ? () => widget.onChanged!(!widget.checked) : null,
        onTapDown:
            isInteractive ? (_) => setState(() => _pressing = true) : null,
        onTapUp:
            isInteractive ? (_) => setState(() => _pressing = false) : null,
        onTapCancel:
            isInteractive ? () => setState(() => _pressing = false) : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Semantics(
            toggled: widget.checked,
            label: widget.semanticLabel,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _trackWidth,
                  height: _trackHeight,
                  decoration: ShapeDecoration(
                    color: trackColor,
                    shape: const StadiumBorder(),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _thumbPosition.value,
                        top: _thumbPadding,
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: const ShapeDecoration(
                            color: Colors.white,
                            shape: CircleBorder(),
                          ),
                        ),
                      ),
                    ],
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

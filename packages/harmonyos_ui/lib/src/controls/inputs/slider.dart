import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style slider.
///
/// A horizontal track with a circular thumb that can be dragged to
/// select a value within a given range. The active track is colored
/// with the accent color.
///
/// Example:
/// ```dart
/// HosSlider(
///   value: _volume,
///   min: 0,
///   max: 100,
///   onChanged: (v) => setState(() => _volume = v),
/// )
/// ```
class HosSlider extends StatefulWidget {
  /// Creates a HarmonyOS slider.
  const HosSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.autofocus = false,
    this.focusNode,
    this.semanticLabel,
  });

  /// The current value.
  final double value;

  /// Called continuously as the slider value changes.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts dragging.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user stops dragging.
  final ValueChanged<double>? onChangeEnd;

  /// The minimum value.
  final double min;

  /// The maximum value.
  final double max;

  /// The number of discrete divisions (null for continuous).
  final int? divisions;

  /// Label for the current value (shown in a tooltip).
  final String? label;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  bool get _isInteractive => onChanged != null;

  @override
  State<HosSlider> createState() => _HosSliderState();
}

class _HosSliderState extends State<HosSlider> {
  bool _hovering = false;
  bool _dragging = false;
  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  // Layout constants
  static const double _trackHeight = 4;
  static const double _thumbRadius = 10;
  static const double _tapTargetSize = 40;

  double get _normalizedValue =>
      (widget.value - widget.min) / (widget.max - widget.min);

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode = widget.focusNode == null;
  }

  @override
  void dispose() {
    if (_internalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  double _getValueFromPosition(double trackWidth, double dx) {
    final double fraction =
        (dx - _thumbRadius) / (trackWidth - _thumbRadius * 2);
    final double clampedFraction = fraction.clamp(0.0, 1.0);
    double value = widget.min + clampedFraction * (widget.max - widget.min);

    if (widget.divisions != null) {
      final double step = (widget.max - widget.min) / widget.divisions!;
      value = widget.min +
          ((value - widget.min) / step).round() * step;
    }

    return value.clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final accent = theme.accentColor;
    final isDark = theme.brightness == Brightness.dark;
    final isInteractive = widget._isInteractive;

    final Color trackColor = isDark
        ? const Color(0xFF404040)
        : const Color(0xFFE5E5E5);
    final Color activeTrackColor;
    final double thumbScale;

    if (!isInteractive) {
      activeTrackColor = theme.disabledColor;
      thumbScale = 1.0;
    } else if (_dragging) {
      activeTrackColor = accent.dark;
      thumbScale = 1.15;
    } else if (_hovering) {
      activeTrackColor = accent.light;
      thumbScale = 1.08;
    } else {
      activeTrackColor = accent.normal;
      thumbScale = 1.0;
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: isInteractive
            ? (details) {
                setState(() => _dragging = true);
                widget.onChangeStart?.call(widget.value);
              }
            : null,
        onPanUpdate: isInteractive
            ? (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final trackWidth = renderBox.size.width;
                final dx = details.localPosition.dx;
                widget.onChanged
                    ?.call(_getValueFromPosition(trackWidth, dx));
              }
            : null,
        onPanEnd: isInteractive
            ? (_) {
                setState(() => _dragging = false);
                widget.onChangeEnd?.call(widget.value);
              }
            : null,
        onTapDown: isInteractive
            ? (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final trackWidth = renderBox.size.width;
                widget.onChanged?.call(
                  _getValueFromPosition(trackWidth, details.localPosition.dx),
                );
              }
            : null,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Semantics(
            label: widget.semanticLabel,
            child: SizedBox(
              height: _tapTargetSize,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth =
                      constraints.maxWidth - _thumbRadius * 2;

                  return CustomPaint(
                    painter: _SliderPainter(
                      trackColor: trackColor,
                      activeTrackColor: activeTrackColor,
                      thumbColor:
                          isInteractive ? accent.normal : theme.disabledColor,
                      thumbScale: thumbScale,
                      thumbRadius: _thumbRadius,
                      trackHeight: _trackHeight,
                      normalizedValue: _normalizedValue,
                      trackWidth: trackWidth,
                    ),
                    size: Size(constraints.maxWidth, _tapTargetSize),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.trackColor,
    required this.activeTrackColor,
    required this.thumbColor,
    required this.thumbScale,
    required this.thumbRadius,
    required this.trackHeight,
    required this.normalizedValue,
    required this.trackWidth,
  });

  final Color trackColor;
  final Color activeTrackColor;
  final Color thumbColor;
  final double thumbScale;
  final double thumbRadius;
  final double trackHeight;
  final double normalizedValue;
  final double trackWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double trackLeft = thumbRadius;
    final double trackRight = size.width - thumbRadius;
    final double thumbCenterX = trackLeft + trackWidth * normalizedValue;

    // Track background
    final RRect trackRect = RRect.fromLTRBR(
      trackLeft,
      centerY - trackHeight / 2,
      trackRight,
      centerY + trackHeight / 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(trackRect, Paint()..color = trackColor);

    // Active track
    final RRect activeRect = RRect.fromLTRBR(
      trackLeft,
      centerY - trackHeight / 2,
      thumbCenterX,
      centerY + trackHeight / 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(activeRect, Paint()..color = activeTrackColor);

    // Thumb
    final double scaledRadius = thumbRadius * thumbScale;
    canvas.drawCircle(
      Offset(thumbCenterX, centerY),
      scaledRadius,
      Paint()
        ..color = thumbColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  @override
  bool shouldRepaint(_SliderPainter oldDelegate) {
    return trackColor != oldDelegate.trackColor ||
        activeTrackColor != oldDelegate.activeTrackColor ||
        thumbColor != oldDelegate.thumbColor ||
        thumbScale != oldDelegate.thumbScale ||
        normalizedValue != oldDelegate.normalizedValue;
  }
}

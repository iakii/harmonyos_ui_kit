import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style linear progress bar.
///
/// A horizontal track that fills with the accent color to indicate
/// progress. Supports both determinate and indeterminate modes.
///
/// Example:
/// ```dart
/// HosProgressBar(value: 0.6) // 60% complete
/// HosProgressBar() // indeterminate
/// ```
class HosProgressBar extends StatefulWidget {
  /// Creates a HarmonyOS progress bar.
  const HosProgressBar({
    super.key,
    this.value,
    this.height = 4,
  });

  /// The progress value (0.0 to 1.0). If null, the bar is indeterminate.
  final double? value;

  /// Height of the bar.
  final double height;

  @override
  State<HosProgressBar> createState() => _HosProgressBarState();
}

class _HosProgressBarState extends State<HosProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5);
    final isIndeterminate = widget.value == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height / 2),
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Track
                    Positioned.fill(child: Container(color: trackColor)),
                    // Fill
                    if (!isIndeterminate)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: totalWidth * widget.value!,
                        child:
                            Container(color: theme.accentColor.normal),
                      )
                    else
                      Positioned(
                        left: totalWidth * (_controller.value * 2 - 1),
                        top: 0,
                        bottom: 0,
                        width: totalWidth * 0.3,
                        child:
                            Container(color: theme.accentColor.normal),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A HarmonyOS-style circular progress indicator.
///
/// A spinning ring with the accent color. Supports both determinate
/// and indeterminate modes.
///
/// Example:
/// ```dart
/// HosProgressRing()
/// HosProgressRing(value: 0.75)
/// ```
class HosProgressRing extends StatelessWidget {
  /// Creates a HarmonyOS progress ring.
  const HosProgressRing({
    super.key,
    this.value,
    this.size = 24,
    this.strokeWidth = 2.5,
  });

  /// The progress value (0.0 to 1.0). If null, indeterminate.
  final double? value;

  /// Size of the ring.
  final double size;

  /// Stroke width.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: value != null
          ? CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.accentColor.normal),
              backgroundColor: theme.dividerColor,
            )
          : CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.accentColor.normal),
            ),
    );
  }
}

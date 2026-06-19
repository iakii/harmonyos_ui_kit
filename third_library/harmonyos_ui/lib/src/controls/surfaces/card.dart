import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style card.
///
/// A rounded container with surface background, subtle border, and
/// optional shadow. Typically used to group related content.
///
/// Example:
/// ```dart
/// HosCard(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Card content'),
///   ),
/// )
/// ```
class HosCard extends StatelessWidget {
  /// Creates a HarmonyOS card.
  const HosCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevated = false,
  });

  /// The card content.
  final Widget child;

  /// Called when the card is tapped (makes it interactive).
  final VoidCallback? onTap;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Border radius override.
  final BorderRadius? borderRadius;

  /// Whether to add shadow/elevation.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: theme.animationDuration,
          decoration: ShapeDecoration(
            color: theme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
            shadows: elevated
                ? [
                    BoxShadow(
                      color: theme.shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

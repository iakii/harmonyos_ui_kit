import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style star rating bar.
///
/// Displays a row of stars that can be tapped to set a rating value.
/// Supports half-star ratings and custom maximum values.
///
/// Example:
/// ```dart
/// HosRatingBar(
///   rating: 3.5,
///   maxRating: 5,
///   onChanged: (value) => setState(() => rating = value),
/// )
/// ```
class HosRatingBar extends StatefulWidget {
  /// Creates a HarmonyOS rating bar.
  const HosRatingBar({
    super.key,
    this.rating = 0.0,
    this.maxRating = 5,
    this.onChanged,
    this.starSize = 24,
    this.spacing = 4,
    this.allowHalf = true,
    this.readOnly = false,
    this.semanticLabel,
  });

  /// The current rating value.
  final double rating;

  /// The maximum rating (number of stars).
  final int maxRating;

  /// Called when the user taps a star.
  final ValueChanged<double>? onChanged;

  /// Size of each star icon.
  final double starSize;

  /// Spacing between stars.
  final double spacing;

  /// Whether to allow half-star ratings.
  final bool allowHalf;

  /// Whether the rating bar is read-only.
  final bool readOnly;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<HosRatingBar> createState() => _HosRatingBarState();
}

class _HosRatingBarState extends State<HosRatingBar> {
  double? _hoverRating;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final accent = theme.accentColor;

    final double displayRating = _hoverRating ?? widget.rating;

    return Semantics(
      label: widget.semanticLabel,
      child: MouseRegion(
        onExit: (_) => setState(() => _hoverRating = null),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.maxRating, (index) {
            final double starValue = index + 1.0;
            final bool isFilled = displayRating >= starValue;
            final bool isHalfFilled = !isFilled &&
                widget.allowHalf &&
                displayRating >= starValue - 0.5;

            return GestureDetector(
              onTap: widget.readOnly
                  ? null
                  : () => widget.onChanged?.call(starValue),
              onTapDown: widget.readOnly
                  ? null
                  : (details) {
                      if (!widget.allowHalf) return;
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final double localX = details.localPosition.dx;
                      final double halfWidth = box.size.width / 2;
                      final double value =
                          localX < halfWidth ? starValue - 0.5 : starValue;
                      widget.onChanged?.call(value);
                    },
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                child: MouseRegion(
                  onEnter: widget.readOnly
                      ? null
                      : (_) =>
                          setState(() => _hoverRating = starValue),
                  child: Icon(
                    isFilled
                        ? Icons.star
                        : isHalfFilled
                            ? Icons.star_half
                            : Icons.star_border,
                    size: widget.starSize,
                    color: isFilled || isHalfFilled
                        ? accent.normal
                        : theme.disabledColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

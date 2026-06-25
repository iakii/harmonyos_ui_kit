import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// HarmonyOS Design System typography scale.
///
/// Uses the HDS type ramp with system font (HarmonyOS Sans if available,
/// otherwise the platform's default sans-serif).
///
/// All text styles have a [TextStyle.leadingDistribution] of
/// [TextLeadingDistribution.even] — the HarmonyOS default.
@immutable
class HarmonyTypography with Diagnosticable {
  /// Creates a [HarmonyTypography] with the given text styles.
  ///
  /// All parameters are required. Use [HarmonyTypography.fromBrightness]
  /// or [HarmonyTypography.standard] for a pre-configured instance.
  const HarmonyTypography({
    required this.headline1,
    required this.headline2,
    required this.headline3,
    required this.title1,
    required this.title2,
    required this.title3,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.overline,
    this.fontFamilyFallback,
  });

  /// Extra-large headline. Typically 32px bold.
  final TextStyle? headline1;

  /// Large headline. Typically 28px bold.
  final TextStyle? headline2;

  /// Medium headline. Typically 24px medium.
  final TextStyle? headline3;

  /// Large title. Typically 20px medium.
  final TextStyle? title1;

  /// Medium title. Typically 18px medium.
  final TextStyle? title2;

  /// Small title. Typically 16px medium.
  final TextStyle? title3;

  /// Body text. Typically 14px regular, line height 22px.
  final TextStyle? body;

  /// Small body text. Typically 12px regular.
  final TextStyle? bodySmall;

  /// Caption text. Typically 11px regular.
  final TextStyle? caption;

  /// Overline / label text. Typically 10px medium, all-caps.
  final TextStyle? overline;

  /// Fallback font family stack applied to all text styles.
  ///
  /// When set, each [TextStyle] in this typography will use this list
  /// as its [TextStyle.fontFamilyFallback], providing platform-level
  /// fallback when the primary font is missing certain glyphs.
  final List<String>? fontFamilyFallback;

  // ------------------------------------------------------------------
  // Factory constructors
  // ------------------------------------------------------------------

  /// Returns a standard HarmonyOS typography scale for the given
  /// [brightness].
  factory HarmonyTypography.fromBrightness(Brightness brightness) {
    return brightness == Brightness.light
        ? HarmonyTypography.light()
        : HarmonyTypography.dark();
  }

  /// Standard light-mode typography.
  factory HarmonyTypography.light() => const HarmonyTypography(
    headline1: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    headline2: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.29,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    headline3: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 1.33,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    title1: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      height: 1.40,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    title2: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      height: 1.44,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    title3: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.50,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    body: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.57,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.50,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    caption: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.45,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    overline: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      height: 1.40,
      letterSpacing: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );

  /// Standard dark-mode typography.
  ///
  /// Same sizes and weights as light, but typically with slightly reduced
  /// letter-spacing for readability on dark backgrounds.
  factory HarmonyTypography.dark() {
    final light = HarmonyTypography.light();
    return light.copyWith(); // For now, identical to light — adapt later if needed
  }

  // ------------------------------------------------------------------
  // Merging & copying
  // ------------------------------------------------------------------

  /// Returns a copy of this typography with the given fields replaced.
  HarmonyTypography copyWith({
    TextStyle? headline1,
    TextStyle? headline2,
    TextStyle? headline3,
    TextStyle? title1,
    TextStyle? title2,
    TextStyle? title3,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? caption,
    TextStyle? overline,
    List<String>? fontFamilyFallback,
  }) {
    return HarmonyTypography(
      headline1: headline1 ?? this.headline1,
      headline2: headline2 ?? this.headline2,
      headline3: headline3 ?? this.headline3,
      title1: title1 ?? this.title1,
      title2: title2 ?? this.title2,
      title3: title3 ?? this.title3,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      caption: caption ?? this.caption,
      overline: overline ?? this.overline,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
    );
  }

  /// Merges [other] into this typography, taking non-null values from
  /// [other] and falling back to this instance.
  HarmonyTypography merge(HarmonyTypography? other) {
    if (other == null) return this;
    return copyWith(
      headline1: other.headline1,
      headline2: other.headline2,
      headline3: other.headline3,
      title1: other.title1,
      title2: other.title2,
      title3: other.title3,
      body: other.body,
      bodySmall: other.bodySmall,
      caption: other.caption,
      overline: other.overline,
      fontFamilyFallback: other.fontFamilyFallback,
    );
  }

  /// Applies a color, font family, and fallback font stack to all text styles.
  HarmonyTypography apply({
    Color? color,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double fontSizeDelta = 0,
  }) {
    final effectiveFallback = fontFamilyFallback ?? this.fontFamilyFallback;
    return HarmonyTypography(
      headline1: headline1?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      headline2: headline2?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      headline3: headline3?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      title1: title1?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      title2: title2?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      title3: title3?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      body: body?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      bodySmall: bodySmall?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      caption: caption?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      overline: overline?.apply(
        color: color,
        fontFamily: fontFamily,
        fontFamilyFallback: effectiveFallback,
        fontSizeDelta: fontSizeDelta,
      ),
      fontFamilyFallback: effectiveFallback,
    );
  }

  /// Linearly interpolates between two typography instances.
  static HarmonyTypography? lerp(
    HarmonyTypography? a,
    HarmonyTypography? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) {
      return HarmonyTypography(
        headline1: TextStyle.lerp(null, b!.headline1, t),
        headline2: TextStyle.lerp(null, b.headline2, t),
        headline3: TextStyle.lerp(null, b.headline3, t),
        title1: TextStyle.lerp(null, b.title1, t),
        title2: TextStyle.lerp(null, b.title2, t),
        title3: TextStyle.lerp(null, b.title3, t),
        body: TextStyle.lerp(null, b.body, t),
        bodySmall: TextStyle.lerp(null, b.bodySmall, t),
        caption: TextStyle.lerp(null, b.caption, t),
        overline: TextStyle.lerp(null, b.overline, t),
        fontFamilyFallback: t < 0.5 ? null : b.fontFamilyFallback,
      );
    }
    if (b == null) {
      return HarmonyTypography(
        headline1: TextStyle.lerp(a.headline1, null, t),
        headline2: TextStyle.lerp(a.headline2, null, t),
        headline3: TextStyle.lerp(a.headline3, null, t),
        title1: TextStyle.lerp(a.title1, null, t),
        title2: TextStyle.lerp(a.title2, null, t),
        title3: TextStyle.lerp(a.title3, null, t),
        body: TextStyle.lerp(a.body, null, t),
        bodySmall: TextStyle.lerp(a.bodySmall, null, t),
        caption: TextStyle.lerp(a.caption, null, t),
        overline: TextStyle.lerp(a.overline, null, t),
        fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : null,
      );
    }
    return HarmonyTypography(
      headline1: TextStyle.lerp(a.headline1, b.headline1, t),
      headline2: TextStyle.lerp(a.headline2, b.headline2, t),
      headline3: TextStyle.lerp(a.headline3, b.headline3, t),
      title1: TextStyle.lerp(a.title1, b.title1, t),
      title2: TextStyle.lerp(a.title2, b.title2, t),
      title3: TextStyle.lerp(a.title3, b.title3, t),
      body: TextStyle.lerp(a.body, b.body, t),
      bodySmall: TextStyle.lerp(a.bodySmall, b.bodySmall, t),
      caption: TextStyle.lerp(a.caption, b.caption, t),
      overline: TextStyle.lerp(a.overline, b.overline, t),
      fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : b.fontFamilyFallback,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('headline1', headline1));
    properties.add(DiagnosticsProperty<TextStyle>('headline2', headline2));
    properties.add(DiagnosticsProperty<TextStyle>('headline3', headline3));
    properties.add(DiagnosticsProperty<TextStyle>('title1', title1));
    properties.add(DiagnosticsProperty<TextStyle>('title2', title2));
    properties.add(DiagnosticsProperty<TextStyle>('title3', title3));
    properties.add(DiagnosticsProperty<TextStyle>('body', body));
    properties.add(DiagnosticsProperty<TextStyle>('bodySmall', bodySmall));
    properties.add(DiagnosticsProperty<TextStyle>('caption', caption));
    properties.add(DiagnosticsProperty<TextStyle>('overline', overline));
    properties.add(IterableProperty<String>('fontFamilyFallback', fontFamilyFallback));
  }
}

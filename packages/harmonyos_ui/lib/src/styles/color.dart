import 'dart:ui' show Color, Brightness;

import 'package:flutter/foundation.dart';

/// A custom accent color with named shade keys.
///
/// Mirrors the fluent_ui `AccentColor` pattern — seven named shades
/// from darkest to lightest, with automatic fallback via alpha blending.
///
/// Extends [Color] directly (not [ColorSwatch]) to avoid version-dependent
/// API breakage in the Flutter SDK.
class HosAccentColor extends Color {
  /// Creates a [HosAccentColor] with the given [swatch] map.
  ///
  /// The [primary] value is typically the integer value of the `'normal'`
  /// shade. The [swatch] map stores all seven shades by name.
  const HosAccentColor(super.value, this._swatch);

  final Map<String, Color> _swatch;

  /// Creates a HosAccentColor from a [_swatch] map.
  ///
  /// The [_swatch] must contain at least `'normal'`. Missing keys fall
  /// back to the next-lighter or next-darker shade with alpha blending.
  factory HosAccentColor.swatch(Map<String, Color> swatch) {
    assert(swatch.containsKey('normal'), 'swatch must contain "normal"');
    return HosAccentColor(swatch['normal']!.toARGB32(), swatch);
  }

  /// The darkest shade.
  Color get darkest =>
      _swatch['darkest'] ?? darker.withValues(alpha: 0.7);

  /// A darker shade.
  Color get darker => _swatch['darker'] ?? dark.withValues(alpha: 0.7);

  /// A slightly darker shade.
  Color get dark => _swatch['dark'] ?? normal.withValues(alpha: 0.8);

  /// The primary / normal shade.
  Color get normal => _swatch['normal']!;

  /// A slightly lighter shade.
  Color get light => _swatch['light'] ?? normal.withValues(alpha: 0.8);

  /// A lighter shade.
  Color get lighter => _swatch['lighter'] ?? light.withValues(alpha: 0.7);

  /// The lightest shade.
  Color get lightest =>
      _swatch['lightest'] ?? lighter.withValues(alpha: 0.7);

  /// Returns the shade appropriate for the default brush in the given
  /// [brightness] context.
  Color defaultBrushFor(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return dark;
      case Brightness.dark:
        return lighter;
    }
  }

  /// Secondary brush — slightly transparent default brush.
  Color secondaryBrushFor(Brightness brightness) {
    return defaultBrushFor(brightness).withValues(alpha: 0.9);
  }

  /// Tertiary brush — more transparent default brush.
  Color tertiaryBrushFor(Brightness brightness) {
    return defaultBrushFor(brightness).withValues(alpha: 0.8);
  }

  /// Linearly interpolate between two [HosAccentColor] instances.
  static HosAccentColor? lerp(
    HosAccentColor? a,
    HosAccentColor? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) {
      return HosAccentColor.swatch({
        'darkest': Color.lerp(null, b!.darkest, t)!,
        'darker': Color.lerp(null, b.darker, t)!,
        'dark': Color.lerp(null, b.dark, t)!,
        'normal': Color.lerp(null, b.normal, t)!,
        'light': Color.lerp(null, b.light, t)!,
        'lighter': Color.lerp(null, b.lighter, t)!,
        'lightest': Color.lerp(null, b.lightest, t)!,
      });
    }
    if (b == null) {
      return HosAccentColor.swatch({
        'darkest': Color.lerp(a.darkest, null, t)!,
        'darker': Color.lerp(a.darker, null, t)!,
        'dark': Color.lerp(a.dark, null, t)!,
        'normal': Color.lerp(a.normal, null, t)!,
        'light': Color.lerp(a.light, null, t)!,
        'lighter': Color.lerp(a.lighter, null, t)!,
        'lightest': Color.lerp(a.lightest, null, t)!,
      });
    }
    return HosAccentColor.swatch({
      'darkest': Color.lerp(a.darkest, b.darkest, t)!,
      'darker': Color.lerp(a.darker, b.darker, t)!,
      'dark': Color.lerp(a.dark, b.dark, t)!,
      'normal': Color.lerp(a.normal, b.normal, t)!,
      'light': Color.lerp(a.light, b.light, t)!,
      'lighter': Color.lerp(a.lighter, b.lighter, t)!,
      'lightest': Color.lerp(a.lightest, b.lightest, t)!,
    });
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HosAccentColor) return false;
    return other.toARGB32() == toARGB32() &&
        mapEquals(other._swatch, _swatch);
  }

  @override
  int get hashCode => toARGB32().hashCode ^ Object.hashAll(_swatch.entries);
}

/// HarmonyOS color palette.
///
/// Provides predefined [HosAccentColor] swatches for the standard
/// HarmonyOS NEXT color system, plus a neutral grey scale.
class HarmonyColors {
  HarmonyColors._();

  /// Transparent color.
  static const Color transparent = Color(0x00000000);

  /// Pure black.
  static const Color black = Color(0xFF000000);

  /// Pure white.
  static const Color white = Color(0xFFFFFFFF);

  // --- Accent colors (HarmonyOS palette) ---

  /// HarmonyOS blue — the default accent color (#007dFF).
  static final HosAccentColor blue = HosAccentColor.swatch({
    'darkest': const Color(0xFF003D80),
    'darker': const Color(0xFF0050A5),
    'dark': const Color(0xFF0066CC),
    'normal': const Color(0xFF007DFF),
    'light': const Color(0xFF3398FF),
    'lighter': const Color(0xFF66B2FF),
    'lightest': const Color(0xFF99CCFF),
  });

  /// HarmonyOS red — for destructive actions and errors.
  static final HosAccentColor red = HosAccentColor.swatch({
    'darkest': const Color(0xFF660000),
    'darker': const Color(0xFF990000),
    'dark': const Color(0xFFCC0000),
    'normal': const Color(0xFFFF0000),
    'light': const Color(0xFFFF3333),
    'lighter': const Color(0xFFFF6666),
    'lightest': const Color(0xFFFF9999),
  });

  /// HarmonyOS green — for success states.
  static final HosAccentColor green = HosAccentColor.swatch({
    'darkest': const Color(0xFF003D1F),
    'darker': const Color(0xFF005C2F),
    'dark': const Color(0xFF007A3F),
    'normal': const Color(0xFF00994F),
    'light': const Color(0xFF33B372),
    'lighter': const Color(0xFF66CC95),
    'lightest': const Color(0xFF99E5B8),
  });

  /// HarmonyOS orange — for warnings.
  static final HosAccentColor orange = HosAccentColor.swatch({
    'darkest': const Color(0xFF663300),
    'darker': const Color(0xFF994D00),
    'dark': const Color(0xFFCC6600),
    'normal': const Color(0xFFFF8000),
    'light': const Color(0xFFFF9933),
    'lighter': const Color(0xFFFFB366),
    'lightest': const Color(0xFFFFCC99),
  });

  /// Neutral grey scale.
  ///
  /// Access shades via index: `HarmonyColors.grey[120]`.
  static const Map<int, Color> grey = {
    10: Color(0xFFF2F2F2),
    20: Color(0xFFE5E5E5),
    30: Color(0xFFD9D9D9),
    40: Color(0xFFCCCCCC),
    50: Color(0xFFBFBFBF),
    60: Color(0xFFB3B3B3),
    70: Color(0xFFA6A6A6),
    80: Color(0xFF999999),
    90: Color(0xFF8C8C8C),
    100: Color(0xFF808080),
    110: Color(0xFF737373),
    120: Color(0xFF666666),
    130: Color(0xFF595959),
    140: Color(0xFF4D4D4D),
    150: Color(0xFF404040),
    160: Color(0xFF333333),
    170: Color(0xFF262626),
    180: Color(0xFF1A1A1A),
    190: Color(0xFF0D0D0D),
  };

  // --- Semantic status colors ---

  /// Warning primary color.
  static const Color warningColor = Color(0xFFFF8000);

  /// Error primary color.
  static const Color errorColor = Color(0xFFFF0000);

  /// Success primary color.
  static const Color successColor = Color(0xFF00994F);

  /// Info primary color.
  static const Color infoColor = Color(0xFF007DFF);
}

/// Extension methods on [Color] to help generate accent swatches.
extension HarmonyColorExtension on Color {
  /// Generates a [HosAccentColor] swatch from this color.
  ///
  /// Dark shades are produced by lerping toward black; light shades by
  /// lerping toward white. The [darkFactors] and [lightFactors] control
  /// how much blending is applied at each step.
  HosAccentColor toAccentColor({
    List<double> darkFactors = const [0.38, 0.30, 0.20],
    List<double> lightFactors = const [0.20, 0.30, 0.38],
  }) {
    assert(darkFactors.length == 3, 'darkFactors must have 3 entries');
    assert(lightFactors.length == 3, 'lightFactors must have 3 entries');

    Color lerpTo(Color other, double factor) {
      return Color.lerp(this, other, factor)!;
    }

    return HosAccentColor.swatch({
      'darkest': lerpTo(HarmonyColors.black, darkFactors[0]),
      'darker': lerpTo(HarmonyColors.black, darkFactors[1]),
      'dark': lerpTo(HarmonyColors.black, darkFactors[2]),
      'normal': this,
      'light': lerpTo(HarmonyColors.white, lightFactors[0]),
      'lighter': lerpTo(HarmonyColors.white, lightFactors[1]),
      'lightest': lerpTo(HarmonyColors.white, lightFactors[2]),
    });
  }

  /// Returns a color that is legible over this color's background.
  ///
  /// Returns [lightColor] when this color's luminance is below 0.5,
  /// otherwise returns [darkColor].
  Color basedOnLuminance({
    Color lightColor = HarmonyColors.white,
    Color darkColor = HarmonyColors.black,
  }) {
    return computeLuminance() < 0.5 ? lightColor : darkColor;
  }
}

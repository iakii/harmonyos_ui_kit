import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'color.dart';
import 'color_tokens.dart';
import 'typography.dart';

// Forward declarations for component themes (defined in later phases).
// Button theme is the only one available in Phase 1.
// Other themes will be added in later phases.

/// HarmonyOS theme data — the central configuration object for the
/// entire UI component library.
///
/// Mirrors fluent_ui's `FluentThemeData` pattern:
/// - Factory constructor with brightness-driven defaults
/// - `raw()` const constructor for internal use
/// - `copyWith()` / `merge()` / `lerp()` for composability
@immutable
class HarmonyThemeData with Diagnosticable {
  /// Creates a [HarmonyThemeData] with sensible HarmonyOS defaults.
  ///
  /// If [brightness] is omitted, defaults to [Brightness.light].
  ///
  /// All parameters are optional — omitted values fall back to
  /// brightness-appropriate defaults.
  factory HarmonyThemeData({
    Brightness? brightness,
    HosAccentColor? accentColor,
    HarmonyColorTokens? colorTokens,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? scaffoldBackgroundColor,
    Color? textColor,
    Color? textSecondaryColor,
    Color? disabledColor,
    Color? dividerColor,
    Color? shadowColor,
    HarmonyTypography? typography,
    Duration? animationDuration,
    Curve? animationCurve,
    VisualDensity? visualDensity,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    // Component themes will be added in later phases
    Map<Object, ThemeExtension<dynamic>>? extensions,
  }) {
    brightness ??= Brightness.light;
    final bool isLight = brightness == Brightness.light;
    final tokens = colorTokens ?? HarmonyColorTokens.fromBrightness(brightness);

    // Resolve typography and apply custom font if provided.
    HarmonyTypography resolvedTypography =
        typography ?? HarmonyTypography.fromBrightness(brightness);
    if (fontFamily != null || fontFamilyFallback != null) {
      resolvedTypography = resolvedTypography.apply(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      );
    }

    return HarmonyThemeData.raw(
      brightness: brightness,
      accentColor: accentColor ?? HarmonyColors.blue,
      colorTokens: tokens,
      backgroundColor: backgroundColor ?? tokens.pageBackground,
      surfaceColor: surfaceColor ?? tokens.surfaceBackground,
      scaffoldBackgroundColor: scaffoldBackgroundColor ?? tokens.pageBackground,
      textColor: textColor ?? tokens.textPrimary,
      textSecondaryColor: textSecondaryColor ?? tokens.textSecondary,
      disabledColor:
          disabledColor ??
          (isLight ? HarmonyColors.grey[50]! : const Color(0xFF404040)),
      dividerColor: dividerColor ?? tokens.dividerColor,
      shadowColor:
          shadowColor ??
          (isLight ? const Color(0x1A000000) : const Color(0x1AFFFFFF)),
      typography: resolvedTypography,
      animationDuration: animationDuration ?? const Duration(milliseconds: 200),
      animationCurve: animationCurve ?? Curves.easeInOut,
      visualDensity: visualDensity ?? VisualDensity.standard,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      extensions: extensions,
    );
  }

  /// Raw constructor — all fields required.
  ///
  /// Used internally by [copyWith], [merge], and [lerp]. Prefer the
  /// factory constructor for normal usage.
  const HarmonyThemeData.raw({
    required this.brightness,
    required this.accentColor,
    required this.colorTokens,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.scaffoldBackgroundColor,
    required this.textColor,
    required this.textSecondaryColor,
    required this.disabledColor,
    required this.dividerColor,
    required this.shadowColor,
    required this.typography,
    required this.animationDuration,
    required this.animationCurve,
    required this.visualDensity,
    this.fontFamily,
    this.fontFamilyFallback,
    this.extensions,
  });

  // --- Convenience factories ---

  /// Light-mode HarmonyOS theme with defaults.
  factory HarmonyThemeData.light() =>
      HarmonyThemeData(brightness: Brightness.light);

  /// Dark-mode HarmonyOS theme with defaults.
  factory HarmonyThemeData.dark() =>
      HarmonyThemeData(brightness: Brightness.dark);

  // ------------------------------------------------------------------
  // Core properties
  // ------------------------------------------------------------------

  /// The overall brightness of the theme (light or dark).
  final Brightness brightness;

  /// Whether this is a light theme.
  bool get isLight => brightness == Brightness.light;

  /// The accent color used for primary actions, selections, etc.
  final HosAccentColor accentColor;

  /// Semantic color tokens (HDS color system).
  final HarmonyColorTokens colorTokens;

  /// The page-level background color.
  final Color backgroundColor;

  /// Surface / card background color.
  final Color surfaceColor;

  /// Scaffold root background color.
  final Color scaffoldBackgroundColor;

  /// Primary text color (highest emphasis).
  final Color textColor;

  /// Secondary text color (medium emphasis).
  final Color textSecondaryColor;

  /// Color used for disabled UI elements.
  final Color disabledColor;

  /// Divider / separator color.
  final Color dividerColor;

  /// Shadow / elevation color.
  final Color shadowColor;

  // ------------------------------------------------------------------
  // Typography
  // ------------------------------------------------------------------

  /// The typography scale for this theme.
  final HarmonyTypography typography;

  /// Custom font family applied to all typography styles.
  ///
  /// When set, this font family is applied to every [TextStyle] in
  /// [typography] via [HarmonyTypography.apply]. If both [fontFamily]
  /// and [typography] are provided, the font family is layered on top
  /// of the custom typography.
  final String? fontFamily;

  /// Fallback font stack applied to all typography styles.
  ///
  /// Used as [TextStyle.fontFamilyFallback] on each text style. This
  /// provides platform-level fallback when the primary font is missing
  /// certain glyphs.
  final List<String>? fontFamilyFallback;

  // ------------------------------------------------------------------
  // Animation
  // ------------------------------------------------------------------

  /// Default animation duration for interactive transitions.
  final Duration animationDuration;

  /// Default animation curve for interactive transitions.
  final Curve animationCurve;

  // ------------------------------------------------------------------
  // Layout
  // ------------------------------------------------------------------

  /// Visual density (compact vs standard vs comfortable).
  final VisualDensity visualDensity;

  // ------------------------------------------------------------------
  // Theme extensions
  // ------------------------------------------------------------------

  /// Arbitrary theme extensions (material's ThemeExtension system).
  final Map<Object, ThemeExtension<dynamic>>? extensions;

  // ------------------------------------------------------------------
  // Composability
  // ------------------------------------------------------------------

  /// Returns a copy of this theme with the given fields replaced.
  HarmonyThemeData copyWith({
    Brightness? brightness,
    HosAccentColor? accentColor,
    HarmonyColorTokens? colorTokens,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? scaffoldBackgroundColor,
    Color? textColor,
    Color? textSecondaryColor,
    Color? disabledColor,
    Color? dividerColor,
    Color? shadowColor,
    HarmonyTypography? typography,
    Duration? animationDuration,
    Curve? animationCurve,
    VisualDensity? visualDensity,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    Map<Object, ThemeExtension<dynamic>>? extensions,
  }) {
    return HarmonyThemeData.raw(
      brightness: brightness ?? this.brightness,
      accentColor: accentColor ?? this.accentColor,
      colorTokens: colorTokens ?? this.colorTokens,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      disabledColor: disabledColor ?? this.disabledColor,
      dividerColor: dividerColor ?? this.dividerColor,
      shadowColor: shadowColor ?? this.shadowColor,
      typography: typography ?? this.typography,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      visualDensity: visualDensity ?? this.visualDensity,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      extensions: extensions ?? this.extensions,
    );
  }

  /// Merges [other] into this theme.
  ///
  /// Non-null fields in [other] take precedence; null fields fall back
  /// to this instance. Typography is deeply merged.
  HarmonyThemeData merge(HarmonyThemeData? other) {
    if (other == null) return this;
    return copyWith(
      brightness: other.brightness,
      accentColor: other.accentColor,
      colorTokens: other.colorTokens,
      backgroundColor: other.backgroundColor,
      surfaceColor: other.surfaceColor,
      scaffoldBackgroundColor: other.scaffoldBackgroundColor,
      textColor: other.textColor,
      textSecondaryColor: other.textSecondaryColor,
      disabledColor: other.disabledColor,
      dividerColor: other.dividerColor,
      shadowColor: other.shadowColor,
      typography: typography.merge(other.typography),
      animationDuration: other.animationDuration,
      animationCurve: other.animationCurve,
      visualDensity: other.visualDensity,
      fontFamily: other.fontFamily ?? fontFamily,
      fontFamilyFallback: other.fontFamilyFallback ?? fontFamilyFallback,
      extensions: other.extensions,
    );
  }

  /// Linearly interpolates between two [HarmonyThemeData] instances.
  static HarmonyThemeData? lerp(
    HarmonyThemeData? a,
    HarmonyThemeData? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) {
      return HarmonyThemeData.raw(
        brightness: b!.brightness,
        accentColor: b.accentColor,
        colorTokens: b.colorTokens,
        backgroundColor:
            Color.lerp(null, b.backgroundColor, t) ?? b.backgroundColor,
        surfaceColor: Color.lerp(null, b.surfaceColor, t) ?? b.surfaceColor,
        scaffoldBackgroundColor:
            Color.lerp(null, b.scaffoldBackgroundColor, t) ??
            b.scaffoldBackgroundColor,
        textColor: Color.lerp(null, b.textColor, t) ?? b.textColor,
        textSecondaryColor:
            Color.lerp(null, b.textSecondaryColor, t) ?? b.textSecondaryColor,
        disabledColor: Color.lerp(null, b.disabledColor, t) ?? b.disabledColor,
        dividerColor: Color.lerp(null, b.dividerColor, t) ?? b.dividerColor,
        shadowColor: Color.lerp(null, b.shadowColor, t) ?? b.shadowColor,
        typography: HarmonyTypography.lerp(null, b.typography, t)!,
        animationDuration: b.animationDuration,
        animationCurve: b.animationCurve,
        visualDensity: b.visualDensity,
        fontFamily: t < 0.5 ? null : b.fontFamily,
        fontFamilyFallback: t < 0.5 ? null : b.fontFamilyFallback,
        extensions: b.extensions,
      );
    }
    if (b == null) {
      return HarmonyThemeData.raw(
        brightness: a.brightness,
        accentColor: a.accentColor,
        colorTokens: a.colorTokens,
        backgroundColor:
            Color.lerp(a.backgroundColor, null, t) ?? a.backgroundColor,
        surfaceColor: Color.lerp(a.surfaceColor, null, t) ?? a.surfaceColor,
        scaffoldBackgroundColor:
            Color.lerp(a.scaffoldBackgroundColor, null, t) ??
            a.scaffoldBackgroundColor,
        textColor: Color.lerp(a.textColor, null, t) ?? a.textColor,
        textSecondaryColor:
            Color.lerp(a.textSecondaryColor, null, t) ?? a.textSecondaryColor,
        disabledColor: Color.lerp(a.disabledColor, null, t) ?? a.disabledColor,
        dividerColor: Color.lerp(a.dividerColor, null, t) ?? a.dividerColor,
        shadowColor: Color.lerp(a.shadowColor, null, t) ?? a.shadowColor,
        typography: HarmonyTypography.lerp(a.typography, null, t)!,
        animationDuration: a.animationDuration,
        animationCurve: a.animationCurve,
        visualDensity: a.visualDensity,
        fontFamily: t < 0.5 ? a.fontFamily : null,
        fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : null,
        extensions: a.extensions,
      );
    }
    return HarmonyThemeData.raw(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      accentColor:
          HosAccentColor.lerp(a.accentColor, b.accentColor, t) ?? a.accentColor,
      colorTokens: t < 0.5 ? a.colorTokens : b.colorTokens,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      surfaceColor: Color.lerp(a.surfaceColor, b.surfaceColor, t)!,
      scaffoldBackgroundColor: Color.lerp(
        a.scaffoldBackgroundColor,
        b.scaffoldBackgroundColor,
        t,
      )!,
      textColor: Color.lerp(a.textColor, b.textColor, t)!,
      textSecondaryColor: Color.lerp(
        a.textSecondaryColor,
        b.textSecondaryColor,
        t,
      )!,
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t)!,
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t)!,
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t)!,
      typography: HarmonyTypography.lerp(a.typography, b.typography, t)!,
      animationDuration: a.animationDuration,
      animationCurve: a.animationCurve,
      visualDensity: a.visualDensity,
      fontFamily: t < 0.5 ? a.fontFamily : b.fontFamily,
      fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : b.fontFamilyFallback,
      extensions: t < 0.5 ? a.extensions : b.extensions,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    properties.add(
      DiagnosticsProperty<HosAccentColor>('accentColor', accentColor),
    );
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(ColorProperty('surfaceColor', surfaceColor));
    properties.add(ColorProperty('textColor', textColor));
    properties.add(
      DiagnosticsProperty<HarmonyTypography>('typography', typography),
    );
    properties.add(
      DiagnosticsProperty<Duration>('animationDuration', animationDuration),
    );
    properties.add(StringProperty('fontFamily', fontFamily));
    properties.add(IterableProperty<String>('fontFamilyFallback', fontFamilyFallback));
  }
}

// --------------------------------------------------------------------
// HarmonyTheme — InheritedTheme wrapper
// --------------------------------------------------------------------

/// Applies a [HarmonyThemeData] to all descendant widgets.
///
/// Usage:
/// ```dart
/// HarmonyTheme(
///   data: HarmonyThemeData(),
///   child: MyApp(),
/// )
/// ```
class HarmonyTheme extends StatelessWidget {
  /// Creates a [HarmonyTheme] that applies the given [data] to [child].
  const HarmonyTheme({super.key, required this.data, required this.child});

  /// The theme data to apply.
  final HarmonyThemeData data;

  /// The widget below this one in the tree.
  final Widget child;

  /// Returns the [HarmonyThemeData] from the nearest [HarmonyTheme]
  /// ancestor.
  ///
  /// Throws if no [HarmonyTheme] ancestor is found.
  static HarmonyThemeData of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No HarmonyTheme found in context');
    return result!;
  }

  /// Returns the [HarmonyThemeData] from the nearest [HarmonyTheme]
  /// ancestor, or null if none exists.
  static HarmonyThemeData? maybeOf(BuildContext context) {
    final theme = context
        .dependOnInheritedWidgetOfExactType<_InheritedHarmonyTheme>();
    return theme?.data;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedHarmonyTheme(
      data: data,
      child: IconTheme(
        data: IconThemeData(color: data.textColor),
        child: DefaultTextStyle(style: data.typography.body!, child: child),
      ),
    );
  }
}

/// Private [InheritedWidget] that propagates [HarmonyThemeData] down
/// the widget tree.
class _InheritedHarmonyTheme extends InheritedWidget {
  const _InheritedHarmonyTheme({required this.data, required super.child});

  final HarmonyThemeData data;

  @override
  bool updateShouldNotify(_InheritedHarmonyTheme oldWidget) {
    return oldWidget.data != data;
  }
}

// --------------------------------------------------------------------
// AnimatedHarmonyTheme — animated theme transitions
// --------------------------------------------------------------------

/// Animated version of [HarmonyTheme] that smoothly transitions between
/// theme data changes.
class AnimatedHarmonyTheme extends ImplicitlyAnimatedWidget {
  /// Creates an [AnimatedHarmonyTheme].
  const AnimatedHarmonyTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeInOut,
    super.duration = const Duration(milliseconds: 200),
  });

  /// The target theme data.
  final HarmonyThemeData data;

  /// The widget below this one in the tree.
  final Widget child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedHarmonyTheme> createState() =>
      _AnimatedHarmonyThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarmonyThemeData>('data', data));
  }
}

class _AnimatedHarmonyThemeState
    extends AnimatedWidgetBaseState<AnimatedHarmonyTheme> {
  HarmonyThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data =
        visitor(
              _data,
              widget.data,
              (dynamic value) =>
                  HarmonyThemeDataTween(begin: value as HarmonyThemeData?),
            )
            as HarmonyThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    return HarmonyTheme(
      data: _data?.evaluate(animation) ?? widget.data,
      child: widget.child,
    );
  }
}

/// Tween for interpolating between two [HarmonyThemeData] instances.
class HarmonyThemeDataTween extends Tween<HarmonyThemeData?> {
  /// Creates a tween from [begin] to [end].
  HarmonyThemeDataTween({super.begin, super.end});

  @override
  HarmonyThemeData? lerp(double t) {
    return HarmonyThemeData.lerp(begin, end, t);
  }
}

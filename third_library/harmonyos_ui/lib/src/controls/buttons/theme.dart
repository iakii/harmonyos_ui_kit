import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Defines the visual properties of a HarmonyOS button.
///
/// Uses [WidgetStateProperty] for state-based styling (hovered, pressed,
/// focused, disabled, etc.).
@immutable
class HosButtonStyle with Diagnosticable {
  /// Creates a [HosButtonStyle].
  const HosButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.overlayColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.padding,
    this.minimumSize,
    this.fixedSize,
    this.maximumSize,
    this.shape,
    this.side,
    this.textStyle,
    this.iconSize,
  });

  /// Background color for each state.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Foreground color (text + icon) for each state.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Overlay color (hover/press ripple) for each state.
  final WidgetStateProperty<Color?>? overlayColor;

  /// Shadow color for each state.
  final WidgetStateProperty<Color?>? shadowColor;

  /// Surface tint color for each state.
  final WidgetStateProperty<Color?>? surfaceTintColor;

  /// Elevation for each state.
  final WidgetStateProperty<double?>? elevation;

  /// Padding (insets around the child).
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Minimum size.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Fixed size (overrides minimum and natural size).
  final WidgetStateProperty<Size?>? fixedSize;

  /// Maximum size.
  final WidgetStateProperty<Size?>? maximumSize;

  /// Shape of the button.
  final WidgetStateProperty<OutlinedBorder?>? shape;

  /// Border side.
  final WidgetStateProperty<BorderSide?>? side;

  /// Text style.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Icon size.
  final double? iconSize;

  /// Returns a copy with the given fields replaced.
  HosButtonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? overlayColor,
    WidgetStateProperty<Color?>? shadowColor,
    WidgetStateProperty<Color?>? surfaceTintColor,
    WidgetStateProperty<double?>? elevation,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Size?>? fixedSize,
    WidgetStateProperty<Size?>? maximumSize,
    WidgetStateProperty<OutlinedBorder?>? shape,
    WidgetStateProperty<BorderSide?>? side,
    WidgetStateProperty<TextStyle?>? textStyle,
    double? iconSize,
  }) {
    return HosButtonStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      shadowColor: shadowColor ?? this.shadowColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      elevation: elevation ?? this.elevation,
      padding: padding ?? this.padding,
      minimumSize: minimumSize ?? this.minimumSize,
      fixedSize: fixedSize ?? this.fixedSize,
      maximumSize: maximumSize ?? this.maximumSize,
      shape: shape ?? this.shape,
      side: side ?? this.side,
      textStyle: textStyle ?? this.textStyle,
      iconSize: iconSize ?? this.iconSize,
    );
  }

  /// Merges [other] into this style (non-null fields take precedence).
  HosButtonStyle merge(HosButtonStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      foregroundColor: other.foregroundColor,
      overlayColor: other.overlayColor,
      shadowColor: other.shadowColor,
      surfaceTintColor: other.surfaceTintColor,
      elevation: other.elevation,
      padding: other.padding,
      minimumSize: other.minimumSize,
      fixedSize: other.fixedSize,
      maximumSize: other.maximumSize,
      shape: other.shape,
      side: other.side,
      textStyle: other.textStyle,
      iconSize: other.iconSize,
    );
  }

  /// Linearly interpolate between two button styles.
  static HosButtonStyle? lerp(
      HosButtonStyle? a, HosButtonStyle? b, double t) {
    if (identical(a, b)) return a;
    return HosButtonStyle(
      backgroundColor:
          _lerpProperties<Color?>(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: _lerpProperties<Color?>(
          a?.foregroundColor, b?.foregroundColor, t),
      overlayColor:
          _lerpProperties<Color?>(a?.overlayColor, b?.overlayColor, t),
      shadowColor:
          _lerpProperties<Color?>(a?.shadowColor, b?.shadowColor, t),
      surfaceTintColor: _lerpProperties<Color?>(
          a?.surfaceTintColor, b?.surfaceTintColor, t),
      elevation:
          _lerpProperties<double?>(a?.elevation, b?.elevation, t),
      padding: _lerpProperties<EdgeInsetsGeometry?>(
          a?.padding, b?.padding, t),
      minimumSize:
          _lerpProperties<Size?>(a?.minimumSize, b?.minimumSize, t),
      fixedSize:
          _lerpProperties<Size?>(a?.fixedSize, b?.fixedSize, t),
      maximumSize:
          _lerpProperties<Size?>(a?.maximumSize, b?.maximumSize, t),
      shape:
          _lerpProperties<OutlinedBorder?>(a?.shape, b?.shape, t),
      side: _lerpProperties<BorderSide?>(a?.side, b?.side, t),
      textStyle:
          _lerpProperties<TextStyle?>(a?.textStyle, b?.textStyle, t),
      iconSize:
          _lerpDouble(a?.iconSize, b?.iconSize, t),
    );
  }

  static WidgetStateProperty<T?>? _lerpProperties<T>(
    WidgetStateProperty<T?>? a,
    WidgetStateProperty<T?>? b,
    double t,
  ) {
    // For simplicity, pick the closer one.
    if (t < 0.5) return a;
    return b;
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b! * t;
    if (b == null) return a * (1 - t);
    return a + (b - a) * t;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<WidgetStateProperty<Color?>?>.has(
        'backgroundColor', backgroundColor));
    properties.add(ObjectFlagProperty<WidgetStateProperty<Color?>?>.has(
        'foregroundColor', foregroundColor));
    properties.add(DoubleProperty('iconSize', iconSize));
  }
}

// --------------------------------------------------------------------
// HosButtonThemeData
// --------------------------------------------------------------------

/// Theme data for HarmonyOS button variants.
@immutable
class HosButtonThemeData with Diagnosticable {
  /// Creates a [HosButtonThemeData].
  const HosButtonThemeData({
    this.defaultButtonStyle,
    this.filledButtonStyle,
    this.outlinedButtonStyle,
    this.textButtonStyle,
    this.iconButtonStyle,
  });

  /// Style for the default button variant.
  final HosButtonStyle? defaultButtonStyle;

  /// Style for the filled (primary) button variant.
  final HosButtonStyle? filledButtonStyle;

  /// Style for the outlined (secondary) button variant.
  final HosButtonStyle? outlinedButtonStyle;

  /// Style for the text (ghost) button variant.
  final HosButtonStyle? textButtonStyle;

  /// Style for the icon button variant.
  final HosButtonStyle? iconButtonStyle;

  /// Returns a copy with the given fields replaced.
  HosButtonThemeData copyWith({
    HosButtonStyle? defaultButtonStyle,
    HosButtonStyle? filledButtonStyle,
    HosButtonStyle? outlinedButtonStyle,
    HosButtonStyle? textButtonStyle,
    HosButtonStyle? iconButtonStyle,
  }) {
    return HosButtonThemeData(
      defaultButtonStyle:
          defaultButtonStyle ?? this.defaultButtonStyle,
      filledButtonStyle:
          filledButtonStyle ?? this.filledButtonStyle,
      outlinedButtonStyle:
          outlinedButtonStyle ?? this.outlinedButtonStyle,
      textButtonStyle: textButtonStyle ?? this.textButtonStyle,
      iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    );
  }

  /// Merges [other] into this theme data.
  HosButtonThemeData merge(HosButtonThemeData? other) {
    if (other == null) return this;
    return HosButtonThemeData(
      defaultButtonStyle:
          defaultButtonStyle?.merge(other.defaultButtonStyle) ??
              other.defaultButtonStyle,
      filledButtonStyle:
          filledButtonStyle?.merge(other.filledButtonStyle) ??
              other.filledButtonStyle,
      outlinedButtonStyle:
          outlinedButtonStyle?.merge(other.outlinedButtonStyle) ??
              other.outlinedButtonStyle,
      textButtonStyle:
          textButtonStyle?.merge(other.textButtonStyle) ??
              other.textButtonStyle,
      iconButtonStyle:
          iconButtonStyle?.merge(other.iconButtonStyle) ??
              other.iconButtonStyle,
    );
  }

  /// Linearly interpolate between two button theme data instances.
  static HosButtonThemeData? lerp(
      HosButtonThemeData? a, HosButtonThemeData? b, double t) {
    if (identical(a, b)) return a;
    return HosButtonThemeData(
      defaultButtonStyle: HosButtonStyle.lerp(
          a?.defaultButtonStyle, b?.defaultButtonStyle, t),
      filledButtonStyle: HosButtonStyle.lerp(
          a?.filledButtonStyle, b?.filledButtonStyle, t),
      outlinedButtonStyle: HosButtonStyle.lerp(
          a?.outlinedButtonStyle, b?.outlinedButtonStyle, t),
      textButtonStyle: HosButtonStyle.lerp(
          a?.textButtonStyle, b?.textButtonStyle, t),
      iconButtonStyle: HosButtonStyle.lerp(
          a?.iconButtonStyle, b?.iconButtonStyle, t),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HosButtonStyle>(
        'defaultButtonStyle', defaultButtonStyle));
    properties.add(DiagnosticsProperty<HosButtonStyle>(
        'filledButtonStyle', filledButtonStyle));
  }
}

// --------------------------------------------------------------------
// HosButtonTheme — InheritedTheme for buttons
// --------------------------------------------------------------------

/// An [InheritedWidget] that provides [HosButtonThemeData] to descendants.
class HosButtonTheme extends InheritedWidget {
  /// Creates a [HosButtonTheme].
  const HosButtonTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// The button theme data.
  final HosButtonThemeData data;

  /// Retrieves the nearest [HosButtonThemeData] from the context.
  static HosButtonThemeData? of(BuildContext context) {
    final theme =
        context.dependOnInheritedWidgetOfExactType<HosButtonTheme>();
    return theme?.data;
  }

  @override
  bool updateShouldNotify(HosButtonTheme oldWidget) {
    return oldWidget.data != data;
  }
}

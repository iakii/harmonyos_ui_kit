import 'dart:ui' show Color, Brightness;

import 'color.dart';

/// Semantic color tokens following the HarmonyOS Design System (HDS).
///
/// Provides light and dark variants for each semantic color role.
/// Components use these tokens instead of raw colors so that the entire
/// UI adapts automatically when brightness changes.
///
/// Tokens are organized by usage category:
/// - **Background**: page, surface, overlay backgrounds
/// - **Text**: primary, secondary, tertiary, inverse
/// - **Stroke**: border, divider, focus ring
/// - **Interactive**: control fills and strokes per state
/// - **Status**: success, warning, error, info
class HarmonyColorTokens {
  const HarmonyColorTokens._({
    required this.pageBackground,
    required this.surfaceBackground,
    required this.overlayBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.strokePrimary,
    required this.strokeSecondary,
    required this.dividerColor,
    required this.focusRingColor,
    required this.controlFillDefault,
    required this.controlFillHover,
    required this.controlFillPressed,
    required this.controlFillDisabled,
    required this.controlStrokeDefault,
    required this.controlStrokeHover,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
  });

  // --- Background tokens ---

  /// The page-level background color (the farthest background).
  final Color pageBackground;

  /// Surface / card background color (elevated above page).
  final Color surfaceBackground;

  /// Overlay / dialog / popup background color.
  final Color overlayBackground;

  // --- Text tokens ---

  /// Primary text color — highest contrast against background.
  final Color textPrimary;

  /// Secondary text color — medium emphasis.
  final Color textSecondary;

  /// Tertiary text color — lowest emphasis (placeholders, disabled text).
  final Color textTertiary;

  /// Inverse text color — used on accent/dark backgrounds.
  final Color textInverse;

  // --- Stroke tokens ---

  /// Primary border / stroke color.
  final Color strokePrimary;

  /// Secondary border / stroke color (lighter).
  final Color strokeSecondary;

  /// Divider / separator color.
  final Color dividerColor;

  /// Focus ring color (visible focus indicator).
  final Color focusRingColor;

  // --- Interactive control tokens ---

  /// Default fill color for interactive controls (e.g. input backgrounds).
  final Color controlFillDefault;

  /// Fill color when hovered.
  final Color controlFillHover;

  /// Fill color when pressed.
  final Color controlFillPressed;

  /// Fill color when disabled.
  final Color controlFillDisabled;

  /// Default stroke color for interactive controls.
  final Color controlStrokeDefault;

  /// Stroke color when hovered.
  final Color controlStrokeHover;

  // --- Status tokens ---

  /// Success state color.
  final Color statusSuccess;

  /// Warning state color.
  final Color statusWarning;

  /// Error state color.
  final Color statusError;

  /// Info state color.
  final Color statusInfo;

  // --- Factory constructors ---

  /// Light-mode color tokens.
  factory HarmonyColorTokens.light() => HarmonyColorTokens._(
    pageBackground: const Color(0xFFF1F3F5),
    surfaceBackground: HarmonyColors.white,
    overlayBackground: HarmonyColors.white,
    textPrimary: const Color(0xFF191919),
    textSecondary: const Color(0xFF999999),
    textTertiary: const Color(0xFFBFBFBF),
    textInverse: HarmonyColors.white,
    strokePrimary: const Color(0xFFE5E5E5),
    strokeSecondary: const Color(0xFFF2F2F2),
    dividerColor: const Color(0xFFE5E5E5),
    focusRingColor: const Color(0xFF007DFF),
    controlFillDefault: const Color(0x0A000000),
    controlFillHover: const Color(0x14000000),
    controlFillPressed: const Color(0x1F000000),
    controlFillDisabled: const Color(0x05000000),
    controlStrokeDefault: const Color(0xFFD9D9D9),
    controlStrokeHover: const Color(0xFFBFBFBF),
    statusSuccess: HarmonyColors.successColor,
    statusWarning: HarmonyColors.warningColor,
    statusError: HarmonyColors.errorColor,
    statusInfo: HarmonyColors.infoColor,
  );

  /// Dark-mode color tokens.
  factory HarmonyColorTokens.dark() => HarmonyColorTokens._(
    pageBackground: const Color(0xFF111111),
    surfaceBackground: const Color(0xFF1E1E1E),
    overlayBackground: const Color(0xFF2A2A2A),
    textPrimary: HarmonyColors.white,
    textSecondary: const Color(0xFF808080),
    textTertiary: const Color(0xFF4D4D4D),
    textInverse: const Color(0xFF191919),
    strokePrimary: const Color(0xFF333333),
    strokeSecondary: const Color(0xFF262626),
    dividerColor: const Color(0xFF333333),
    focusRingColor: const Color(0xFF3398FF),
    controlFillDefault: const Color(0x0AFFFFFF),
    controlFillHover: const Color(0x14FFFFFF),
    controlFillPressed: const Color(0x1FFFFFFF),
    controlFillDisabled: const Color(0x05FFFFFF),
    controlStrokeDefault: const Color(0xFF404040),
    controlStrokeHover: const Color(0xFF595959),
    statusSuccess: const Color(0xFF33B372),
    statusWarning: const Color(0xFFFFB366),
    statusError: const Color(0xFFFF6666),
    statusInfo: const Color(0xFF66B2FF),
  );

  /// Returns the appropriate token set for the given [brightness].
  factory HarmonyColorTokens.fromBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return HarmonyColorTokens.light();
      case Brightness.dark:
        return HarmonyColorTokens.dark();
    }
  }
}

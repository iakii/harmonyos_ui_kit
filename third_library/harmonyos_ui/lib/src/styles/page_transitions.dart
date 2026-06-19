import 'package:flutter/widgets.dart';

/// HarmonyOS-style page transition builder.
///
/// Combines a horizontal slide with a brief fade for a smooth
/// navigation feel consistent with HarmonyOS NEXT design.
///
/// Usage will be integrated in a future phase when page transitions
/// are fully implemented.
class HarmonyOSPageTransitionsBuilder {
  /// Creates an [HarmonyOSPageTransitionsBuilder].
  const HarmonyOSPageTransitionsBuilder();

  /// Builds the transition animation wrapping [child].
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut.flipped,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: curvedAnimation,
          curve: const Interval(0.0, 0.3),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

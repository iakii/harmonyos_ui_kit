import 'package:flutter/material.dart';

/// A page route that applies a HarmonyOS-style transition animation.
class HarmonyOSPageRoute<T> extends MaterialPageRoute<T> {
  /// Creates a HarmonyOS-styled page route.
  HarmonyOSPageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
  });
}

/// A page factory that uses HarmonyOS transitions.
///
/// Use in [Navigator.pages] lists with the [Router] API.
class HarmonyOSPage<T> extends Page<T> {
  /// Creates a HarmonyOS-styled page.
  const HarmonyOSPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// The content of the page.
  final Widget child;

  /// Whether the page should be kept in memory when inactive.
  final bool maintainState;

  /// Whether this is a fullscreen dialog.
  final bool fullscreenDialog;

  @override
  Route<T> createRoute(BuildContext context) {
    return HarmonyOSPageRoute<T>(
      builder: (_) => child,
      settings: this,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

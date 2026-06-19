import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

/// A HarmonyOS-style page scaffold.
///
/// Provides the standard HarmonyOS page structure with optional app bar,
/// body, and bottom navigation area. Applies the HDS background color
/// and safe area padding automatically.
///
/// Example:
/// ```dart
/// HosPage(
///   title: 'Settings',
///   body: ListView(children: [...]),
/// )
/// ```
class HosPage extends StatelessWidget {
  /// Creates a HarmonyOS-styled page.
  const HosPage({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.padding,
    this.backgroundColor,
    this.appBarHeight = 92.0,
    this.immersiveAppBar = true,
    this.showAppBar = false,
  });

  /// Title shown in the app bar.
  final String? title;

  /// Leading widget in the app bar (before the title).
  final Widget? leading;

  /// Action widgets in the app bar (after the title).
  final List<Widget>? actions;

  /// The main body content.
  final Widget? body;

  /// Bottom bar (e.g. bottom navigation).
  final Widget? bottomBar;

  /// Floating action button.
  final Widget? floatingActionButton;

  /// Padding around the body content.
  final EdgeInsetsGeometry? padding;

  /// Background color override.
  final Color? backgroundColor;

  /// Height of the app bar. Defaults to 92 vp.
  final double appBarHeight;

  /// Whether to enable the immersive light effect on the app bar.
  ///
  /// Passed through to [HosAppBar.immersive]. Defaults to `true`.
  final bool immersiveAppBar;

  /// Whether to show the app bar.
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;

    final hosAppBar = showAppBar
        ? HosAppBar(
            title: title,
            leading: leading,
            actions: actions,
            height: appBarHeight,
            immersive: immersiveAppBar,
          )
        : null;

    final bottomWidget = Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: bottomBar ?? const SizedBox.shrink(),
    );

    final bodyWidget = Positioned.fill(child: body ?? const SizedBox.shrink());

    // --- Immersive mode: Stack-based layout ---
    return Scaffold(
      backgroundColor: bg,
      appBar: hosAppBar,
      extendBody: true,
      // resizeToAvoidBottomInset: false,
      // persistentFooterAlignment: AlignmentDirectional.bottomCenter,
      // persistentFooterButtons: [
      //   HosButton(child: Text('test'), onPressed: () {}),
      // ],
      // extendBodyBehindAppBar: immersiveAppBar,
      body: Stack(
        fit: StackFit.passthrough,
        children: [bodyWidget, bottomWidget],
      ),
      // body: body ?? const SizedBox.shrink(),
      // bottomNavigationBar: BottomAppBar(
      //   notchMargin: .0,
      //   // shadowColor: Colors.transparent,
      //   color: Colors.transparent,
      //   // Apply a blur effect to the bottom navigation bar
      //   // height: bottomBar != null ? kBottomNavigationBarHeight + 14 : 0.0,
      //   shape: const CircularNotchedRectangle(),
      //   elevation: 0,
      //   child:
      //       bottomBar ??
      //       const SizedBox.shrink(), // Placeholder to avoid overlap with bottomBar
      // ),
      // floatingActionButtonLocation:
      //     FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: floatingActionButton,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:harmonyos_ui/src/widgets/custome_scroll_behavior.dart'
    show AppScrollBehaviour;

import 'styles/theme.dart';

// --------------------------------------------------------------------
// HarmonyOSApp
// --------------------------------------------------------------------

/// The root widget for a HarmonyOS-styled Flutter application.
///
/// Wraps [MaterialApp] and injects the HarmonyOS theme via
/// [AnimatedHarmonyTheme]. Uses Material's navigation infrastructure
/// but overrides the visual theme with HarmonyOS Design System styling.
///
/// Two constructors are provided:
/// - The default constructor uses [Navigator] with [home], [routes], etc.
/// - The `.router()` constructor uses [Router] with [routerConfig].
///
/// Example (Navigator-based):
/// ```dart
/// HarmonyOSApp(
///   title: 'My App',
///   home: MyHomePage(),
///   theme: HarmonyThemeData.light(),
///   darkTheme: HarmonyThemeData.dark(),
/// )
/// ```
///
/// Example (Router-based):
/// ```dart
/// HarmonyOSApp.router(
///   routerConfig: myRouter,
///   theme: HarmonyThemeData.light(),
/// )
/// ```
class HarmonyOSApp extends StatefulWidget {
  /// Creates a HarmonyOS-styled application using a [Navigator].
  const HarmonyOSApp({
    super.key,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.color,
    this.debugShowCheckedModeBanner = true,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.navigatorKey,
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.builder,
  }) : _useRouter = false,
       routerConfig = null;

  /// Creates a HarmonyOS-styled application using a [Router].
  const HarmonyOSApp.router({
    super.key,
    this.title = '',
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.color,
    this.debugShowCheckedModeBanner = true,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.routerConfig,
    this.builder,
  }) : _useRouter = true,
       home = null,
       routes = null,
       navigatorKey = null,
       initialRoute = null,
       onGenerateRoute = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       navigatorObservers = null;

  // ------------------------------------------------------------------
  // Properties
  // ------------------------------------------------------------------

  /// A one-line description used to identify the app.
  final String title;

  /// The light theme data.
  final HarmonyThemeData? theme;

  /// The dark theme data.
  final HarmonyThemeData? darkTheme;

  /// Determines which theme to use.
  final ThemeMode? themeMode;

  /// The primary color to use for the app.
  final Color? color;

  /// Whether to show the debug banner in checked mode.
  final bool debugShowCheckedModeBanner;

  /// The initial locale for the app.
  final Locale? locale;

  /// Delegates that produce localized values.
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Callback for locale list resolution.
  final LocaleListResolutionCallback? localeListResolutionCallback;

  /// Callback for locale resolution.
  final LocaleResolutionCallback? localeResolutionCallback;

  /// The locales the app has been localized for.
  final List<Locale> supportedLocales;

  /// Whether to show performance overlay.
  final bool showPerformanceOverlay;

  /// Whether to show the semantics debugger.
  final bool showSemanticsDebugger;

  /// Whether to show the widget inspector.
  final bool debugShowWidgetInspector;

  // Navigator-based properties
  /// The home widget.
  final Widget? home;

  /// The route table.
  final Map<String, WidgetBuilder>? routes;

  /// A key to use for the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The initial route name.
  final String? initialRoute;

  /// Callback to generate a route from a name.
  final RouteFactory? onGenerateRoute;

  /// Callback to generate initial routes.
  final InitialRouteListFactory? onGenerateInitialRoutes;

  /// Callback for unknown routes.
  final RouteFactory? onUnknownRoute;

  /// Observers for the navigator.
  final List<NavigatorObserver>? navigatorObservers;

  // Router-based properties
  /// The router configuration.
  final RouterConfig<Object>? routerConfig;

  /// Whether to use the router-based constructor.
  final bool _useRouter;

  /// A builder for inserting widgets above the navigator/router.
  final TransitionBuilder? builder;

  @override
  State<HarmonyOSApp> createState() => _HarmonyOSAppState();
}

class _HarmonyOSAppState extends State<HarmonyOSApp> {
  @override
  Widget build(BuildContext context) {
    // Determine effective theme
    final themeMode = widget.themeMode ?? ThemeMode.system;
    final Brightness platformBrightness = MediaQuery.platformBrightnessOf(
      context,
    );

    final HarmonyThemeData effectiveTheme;
    switch (themeMode) {
      case ThemeMode.system:
        effectiveTheme = platformBrightness == Brightness.dark
            ? (widget.darkTheme ?? widget.theme ?? HarmonyThemeData.dark())
            : (widget.theme ?? HarmonyThemeData.light());
        break;
      case ThemeMode.light:
        effectiveTheme = widget.theme ?? HarmonyThemeData.light();
        break;
      case ThemeMode.dark:
        effectiveTheme =
            widget.darkTheme ?? widget.theme ?? HarmonyThemeData.dark();
        break;
    }

    // Build Material theme from HarmonyOS theme for compatibility
    final materialTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: effectiveTheme.accentColor.normal,
        brightness: effectiveTheme.brightness,
      ),
      scaffoldBackgroundColor: effectiveTheme.scaffoldBackgroundColor,
      disabledColor: effectiveTheme.disabledColor,
      dividerColor: effectiveTheme.dividerColor,
      shadowColor: effectiveTheme.shadowColor,
      visualDensity: effectiveTheme.visualDensity,
      useMaterial3: true,
    );

    final Widget app = widget._useRouter
        ? MaterialApp.router(
            routerConfig: widget.routerConfig,
            title: widget.title,
            scrollBehavior: AppScrollBehaviour(),
            theme: materialTheme,
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            locale: widget.locale,
            localizationsDelegates: widget.localizationsDelegates,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            supportedLocales: widget.supportedLocales,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            builder: (context, child) =>
                _harmonyosBuilder(context, child, effectiveTheme),
          )
        : MaterialApp(
            title: widget.title,
            theme: materialTheme,
            scrollBehavior: AppScrollBehaviour(),
            debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
            locale: widget.locale,
            localizationsDelegates: widget.localizationsDelegates,
            localeListResolutionCallback: widget.localeListResolutionCallback,
            localeResolutionCallback: widget.localeResolutionCallback,
            supportedLocales: widget.supportedLocales,
            showPerformanceOverlay: widget.showPerformanceOverlay,
            showSemanticsDebugger: widget.showSemanticsDebugger,
            home: widget.home,
            routes: widget.routes ?? const <String, WidgetBuilder>{},
            navigatorKey: widget.navigatorKey,
            initialRoute: widget.initialRoute,
            onGenerateRoute: widget.onGenerateRoute,
            onGenerateInitialRoutes: widget.onGenerateInitialRoutes,
            onUnknownRoute: widget.onUnknownRoute,
            navigatorObservers:
                widget.navigatorObservers ?? const <NavigatorObserver>[],
            builder: (context, child) =>
                _harmonyosBuilder(context, child, effectiveTheme),
          );

    return app;
  }

  Widget _harmonyosBuilder(
    BuildContext context,
    Widget? child,
    HarmonyThemeData theme,
  ) {
    Widget themed = AnimatedHarmonyTheme(
      data: theme,
      duration: theme.animationDuration,
      curve: theme.animationCurve,
      child: child!,
    );

    if (widget.builder != null) {
      return widget.builder!(context, themed);
    }
    return themed;
  }
}

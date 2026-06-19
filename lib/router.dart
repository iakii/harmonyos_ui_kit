import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart' hide HarmonyOSPage;
import 'pages/harmony.dart' show HarmonyOSPage;
import 'pages/js_parse.dart' show JsParsePage;
import 'pages/glass_kit.dart' show GlassKitPage;
import 'pages/glass_page.dart' show GlassPage;
import 'pages/immersive.dart' show ImmersivePage;
import 'pages/icon_preview.dart' show IconPreviewPage;
import 'pages/layout.dart' show AppLayout;

/// 全局路由配置。
///
/// 使用 GoRouter ShellRoute，所有页面包裹在 AppLayout 中。
final router = GoRouter(
  // initialLocation: '/immersive',
  errorBuilder: (context, state) => HosPage(
    title: 'Page Not Found',
    body: Column(
      children: [
        const Text('Page not found'),
        HosButton(
          onPressed: () => context.go('/'),
          child: const Text('Go Home'),
        ),
      ],
    ),
  ),
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppLayout(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const HarmonyOSPage(title: 'HarmonyOS UI'),
        ),
        GoRoute(
          path: '/js_parse',
          builder: (context, state) => const JsParsePage(),
        ),
        GoRoute(path: '/glass', builder: (context, state) => const GlassPage()),

        GoRoute(
          path: '/glass_kit',
          builder: (context, state) => const GlassKitPage(),
        ),
        GoRoute(
          path: '/icons',
          builder: (context, state) => const IconPreviewPage(),
        ),
      ],
    ),

    GoRoute(
      path: '/immersive',
      builder: (context, state) => const ImmersivePage(),
    ),
  ],
);

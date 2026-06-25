import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart' hide HarmonyOSPage;
import 'package:rohos_app/presentation/pages/js_gallery/layout.dart'
    show GalleryLayout;
import 'package:rohos_app/presentation/pages/loading_page.dart'
    show LoadingPage;
import 'package:rohos_app/presentation/pages/dynamic_html_view_page.dart'
    show DynamicHtml2ViewPage;
import 'package:rohos_app/presentation/pages/rust_daily/rust_daily_page.dart'
    show RustDailyPage;
import 'package:rohos_app/presentation/pages/rust_daily/rust_daily_detail_page.dart'
    show RustDailyDetailPage;
import 'package:rohos_app/presentation/pages/splash_page.dart';
import 'presentation/pages/harmony.dart' show HarmonyOSPage;
import 'presentation/pages/js_parse.dart' show JsParsePage;
import 'presentation/pages/glass_kit.dart' show GlassKitPage;
import 'presentation/pages/glass_page.dart' show GlassPage;
import 'presentation/pages/immersive.dart' show ImmersivePage;
import 'presentation/pages/icon_preview.dart' show IconPreviewPage;
import 'presentation/pages/js_gallery/gallery_page.dart'
    show GalleryContentPage, GalleryPage;
import 'presentation/pages/js_gallery/detail_page.dart' show DetailPage;
import 'presentation/pages/layout.dart' show AppLayout;

/// 全局路由配置。
///
/// 使用 GoRouter ShellRoute，所有页面包裹在 AppLayout 中。
final router = GoRouter(
  initialLocation: '/splash',
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
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
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

    ShellRoute(
      routes: [
        GoRoute(
          path: '/js_gallery',
          builder: (context, state) => const GalleryPage(),
          routes: [],
        ),
        GoRoute(
          path: '/js_gallery_detail',
          builder: (context, state) => DetailPage(
            url: (state.extra as Map<String, dynamic>)['url'] as String,
            title:
                (state.extra as Map<String, dynamic>)['title'] as String? ?? '',
          ),
        ),
        GoRoute(
          path: '/js_gallery_list',
          builder: (context, state) {
            return GalleryContentPage(
              url: (state.extra as Map<String, dynamic>)['url'] as String,
              title: (state.extra as Map<String, dynamic>)['title'] as String,
              showAppBar: true,
            );
          },
        ),
        GoRoute(
          path: '/loading',
          builder: (context, state) => const LoadingPage(),
        ),
      ],
      builder: (context, state, child) => GalleryLayout(child: child),
    ),

    GoRoute(
      path: '/webF',
      builder: (context, state) => const DynamicHtml2ViewPage(),
    ),
    GoRoute(
      path: '/rust',
      builder: (context, state) {
        if (state.extra == null) {
          return const RustDailyPage();
        }
        final extra = state.extra as Map<String, dynamic>;
        final type = extra['type'] as String?;
        final url = extra['url'] as String?;
        final title = extra['title'] as String? ?? '';
        if (type == 'detail' && url != null) {
          return RustDailyDetailPage(url: url, title: title);
        }
        return const RustDailyPage();
      },
    ),
    GoRoute(
      path: '/immersive',
      builder: (context, state) => const ImmersivePage(),
    ),
  ],
);

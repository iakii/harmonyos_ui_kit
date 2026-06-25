import 'package:flutter/material.dart' show Colors;
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/presentation/providers/init/rust_bridge_provider.dart'
    show rustLibInitProvider;

import 'presentation/pages/splash_page.dart';
import 'core/theme/app_theme_provider.dart';
import 'router.dart';

/// 应用根组件。
///
/// 使用 [HarmonyOSApp.router] 构建，集成 Riverpod 状态管理和 HarmonyOS 主题系统。
/// 在 Rust FFI 桥接初始化完成前显示启动页。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 RustLib 初始化状态
    final rustInit = ref.watch(rustLibInitProvider);

    // 监听主题模式（可通过 Provider 动态切换）
    final themeMode = ref.watch(themeModeProvider);

    return rustInit.when(
      loading: () => const _AppShell(themeMode: ThemeMode.system),
      error: (error, stack) => _AppShell(
        themeMode: themeMode,
        showError: true,
        errorMessage: error.toString(),
        onRetry: () => ref.invalidate(rustLibInitProvider),
      ),
      data: (_) => _AppShell(themeMode: themeMode, showSplash: false),
    );
  }
}

/// 内部壳组件，统一包裹 [HarmonyOSApp.router] 或启动/错误页。
///
/// 避免在 [ConsumerWidget.build] 中多次构建主题数据。
class _AppShell extends StatelessWidget {
  const _AppShell({
    required this.themeMode,
    this.showSplash = true,
    this.showError = false,
    this.errorMessage,
    this.onRetry,
  });

  final ThemeMode themeMode;
  final bool showSplash;
  final bool showError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return HarmonyOSApp.router(
      title: 'Rohos App',
      debugShowCheckedModeBanner: false,
      theme: HarmonyThemeData.light().copyWith(fontFamily: 'HarmonyOS Sans SC'),
      darkTheme: HarmonyThemeData.dark().copyWith(
        fontFamily: 'HarmonyOS Sans SC',
      ),
      themeMode: themeMode,
      routerConfig: showSplash ? _splashRouter(errorMessage, onRetry) : router,
    );
  }
}

/// 启动阶段使用的路由 —— 所有路径都指向启动页（或错误页）。
GoRouter _splashRouter(String? errorMessage, VoidCallback? onRetry) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (errorMessage != null) {
            return HosPage(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('初始化失败'),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (onRetry != null)
                      HosButton(onPressed: onRetry, child: const Text('重试')),
                  ],
                ),
              ),
            );
          }
          return const SplashPage();
        },
      ),
    ],
  );
}

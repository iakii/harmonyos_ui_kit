import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/providers/rust_bridge_provider.dart'
    show rustLibInitProvider;

import 'providers/theme_provider.dart';
import 'router.dart';

/// 应用根组件。
///
/// 使用 [HarmonyOSApp.router] 构建，集成 Riverpod 状态管理和 HarmonyOS 主题系统。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 RustLib 初始化（FutureProvider 自动管理生命周期）
    ref.watch(rustLibInitProvider);

    // 监听主题模式（可通过 Provider 动态切换）
    final themeMode = ref.watch(themeModeProvider);

    return HarmonyOSApp.router(
      title: 'Rohos App',
      debugShowCheckedModeBanner: false,
      theme: HarmonyThemeData.light(),
      darkTheme: HarmonyThemeData.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

import 'package:bot_toast/bot_toast.dart' show BotToastInit;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/theme/app_theme_provider.dart';
import 'router.dart';

// 1. 创建全局上下文管理类
class GlobalContext {
  static late BuildContext _context;

  static void setContext(BuildContext context) {
    GlobalContext._context = context;
  }

  static BuildContext get context {
    return _context;
  }
}

/// 应用根组件。
///
/// 使用 [HarmonyOSApp.router] 构建，集成 Riverpod 状态管理和 HarmonyOS 主题系统。
/// 在 Rust FFI 桥接初始化完成前显示启动页。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 RustLib 初始化状态
    // 保存context到全局
    GlobalContext.setContext(context);

    // 监听主题模式（可通过 Provider 动态切换）
    final themeMode = ref.watch(themeModeProvider);

    return HarmonyOSApp.router(
      title: 'Rohos App',
      builder: BotToastInit(),
      debugShowCheckedModeBanner: false,
      theme: HarmonyThemeData.light().copyWith(fontFamily: 'HarmonyOS Sans SC'),
      darkTheme: HarmonyThemeData.dark().copyWith(
        fontFamily: 'HarmonyOS Sans SC',
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

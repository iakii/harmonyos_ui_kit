import 'package:flutter/material.dart' show Colors, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/presentation/widgets/loading.dart' show Loading;
import 'package:rohos_app/router.dart' show router;

import '../providers/init/rust_bridge_provider.dart' show rustLibInitProvider;

/// 启动页。
///
/// 在 [rustLibInitProvider] 完成初始化前显示，展示应用名称和加载动画。
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HarmonyTheme.of(context);

    // 监听 Rust 初始化状态，初始化完成后自动导航到首页
    ref.listen(rustLibInitProvider, (prev, next) {
      next.whenOrNull(
        data: (_) =>
            WidgetsBinding.instance.addPostFrameCallback((_) => router.go('/')),
        error: (Object error, StackTrace stackTrace) {},
      );
    });

    return HosPage(
      backgroundColor: theme.accentColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HarmonyOS UI',
              style: theme.typography.title1?.copyWith(
                color: Colors.white.withValues(alpha: 30),
              ),
            ),
            const SizedBox(height: 8),
            Loading(size: 80, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              '正在加载…',
              style: theme.typography.body?.copyWith(
                color: Colors.white.withValues(alpha: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

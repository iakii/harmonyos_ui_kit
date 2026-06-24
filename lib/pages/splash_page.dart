import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:rohos_app/widgets/loading.dart' show Loading;

/// 启动页。
///
/// 在 [rustLibInitProvider] 完成初始化前显示，展示应用名称和加载动画。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return HosPage(
      backgroundColor: theme.surfaceColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Loading(size: 80),
            const SizedBox(height: 24),
            Text(
              'Rohos App',
              style: theme.typography.title1?.copyWith(color: theme.textColor),
            ),
            const SizedBox(height: 8),

            Icon(
              HMIcons.harmonyos,
              size: 48,
              color: theme.textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),

            Text(
              '正在加载…',
              style: theme.typography.body?.copyWith(
                color: theme.textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

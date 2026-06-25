import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';

/// 加载中状态（无数据）。
class DetailLoadingWidget extends StatelessWidget {
  const DetailLoadingWidget({super.key, required this.theme});

  final HarmonyThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Loading(size: 64),
          const SizedBox(height: 16),
          Text('正在初始化...', style: theme.typography.caption),
        ],
      ),
    );
  }
}

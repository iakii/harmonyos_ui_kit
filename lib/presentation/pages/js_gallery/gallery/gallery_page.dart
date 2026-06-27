import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';
import 'package:rohos_app/presentation/pages/js_gallery/widgets/setting_panel.dart'
    show SettingPanel;
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart'
    show jsConfigProvider;
import 'package:rohos_app/presentation/providers/js_gallery/plugin_info_provider.dart'
    show pluginInfoProvider;
import 'package:rohos_app/presentation/widgets/async_value_widget.dart';
import 'package:rohos_app/presentation/widgets/loading.dart' show Loading;
import 'gallery_body.dart' show GalleryBody;

/// 图集展示页。
///
/// 从 meitule.js 的 pluginInfo 获取菜单和标题，
/// 通过 getPage 加载图集列表，以 GridView 展示。
class GalleryPage extends HookConsumerWidget {
  const GalleryPage({super.key});

  void showSetting(BuildContext context) {
    showHosBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SettingPanel();
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(
      jsConfigProvider.select((selector) => selector.value?.name),
    );

    if (assets == null || assets == '') {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HosAppBar(
          leading: Icon(HMIcons.harmonyos),
          actions: [
            IconButton(
              icon: const Icon(HMIcons.squareGrid2x2CheckmarkTopleftFilled),
              onPressed: () => showSetting(context),
            ),
          ],
          title: '未配置资源',
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(HMIcons.artGallery, size: 64),
              const SizedBox(height: 16),
              const Text('请先配置 JS 源文件'),
              const SizedBox(height: 8),
              HosTextButton(
                onPressed: () => showSetting(context),
                child: const Text(
                  '去设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "HarmonyOs Sans SC",
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pluginInfoAsync = ref.watch(pluginInfoProvider);
    final selectedTabIndex = useState(0);

    return RepaintBoundary(
      child: AsyncValueWidget<PluginInfo>(
      value: pluginInfoAsync,
      error: (err, _) => HosPage(
        showAppBar: true,
        title: '图集',
        leading: Icon(HMIcons.harmonyos),
        body: HosErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(pluginInfoProvider),
        ),
      ),
      loading: HosPage(
        showAppBar: true,
        title: '图集',
        leading: Icon(HMIcons.harmonyos),
        body: const Center(child: Loading(size: 64)),
      ),
      data: (pluginInfo) => GalleryBody(
        pluginInfo: pluginInfo,
        selectedTabIndex: selectedTabIndex,
      ),
    ),
  );
  }
}

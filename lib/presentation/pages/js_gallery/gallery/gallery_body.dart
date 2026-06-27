import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';
import 'package:rohos_app/presentation/pages/js_gallery/widgets/search_panel.dart'
    show showSearchPanel;
import 'package:rohos_app/presentation/pages/js_gallery/widgets/setting_panel.dart'
    show SettingPanel;
import 'package:rohos_app/router.dart' show router;

import 'gallery_content_page.dart' show GalleryContentPage;
import 'gallery_menu_bar.dart' show GalleryMenuBar;

/// 插件信息加载完成后渲染的主体内容。
///
/// 仅负责协调菜单栏和图集内容区，两者通过 [currentUrl] 解耦：
/// - [GalleryMenuBar] 接收 [menus]，回传选中的菜单索引
/// - [GalleryContentPage] 只接收 [url]，独立管理分页/缓存/错误
class GalleryBody extends HookConsumerWidget {
  const GalleryBody({
    super.key,
    required this.pluginInfo,
    required this.selectedTabIndex,
  });

  final PluginInfo pluginInfo;
  final ValueNotifier<int> selectedTabIndex;

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
    final menus = pluginInfo.menus;
    final website = pluginInfo.website;
    // 当前选中菜单对应的完整 URL
    final currentMenu = menus.isNotEmpty ? menus[selectedTabIndex.value] : null;
    final currentUrl = currentMenu != null
        ? '$website${currentMenu.path}'
        : website;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HosAppBar(
        leading: Icon(HMIcons.harmonyos),
        actions: [
          IconButton(
            icon: Icon(HMIcons.magnifyingglass),
            onPressed: () => showSearchPanel(context),
          ),

          IconButton(
            icon: const Icon(HMIcons.houseFill),
            onPressed: () => router.go('/'),
          ),

          IconButton(
            icon: const Icon(HMIcons.squareGrid2x2CheckmarkTopleftFilled),
            onPressed: () => showSetting(context),
          ),
        ],
        title: pluginInfo.name,
      ),
      body: Stack(
        children: [
          GalleryContentPage(url: currentUrl),

          GalleryMenuBar(
            menus: menus,
            selectedIndex: selectedTabIndex.value,
            onChanged: (i) {
              selectedTabIndex.value = i;
            },
          ),
        ],
      ),
    );
  }
}

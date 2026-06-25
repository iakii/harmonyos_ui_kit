import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/models/rust_daily_data.dart';
import 'package:rohos_app/pages/rust_daily_list_tab.dart';
import 'package:rohos_app/router.dart' show router;

/// Rust Daily 列表主页。
///
/// Tab 容器：顶部 [HosTabBar] + [PageView]，每个 tab 对应一个
/// [RustDailyListTab]，通过 [AutomaticKeepAliveClientMixin] 保持存活。
///
/// 文章详情跳转由各 [RustDailyListTab] 内部处理（push `/rust` detail）。
class RustDailyPage extends HookConsumerWidget {
  const RustDailyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTabIndex = useState(0);
    final listTabs = RustDailyTab.defaultListTabs();

    final pageController = useRef(PageController());
    useEffect(() {
      return () => pageController.value.dispose();
    }, []);

    return HosPage(
      title: 'Rust Daily',
      showAppBar: true,
      leading: Navigator.of(context).canPop()
          ? const BackIcon()
          : const Icon(HMIcons.harmonyos, size: 30),
      actions: [
        IconButton(
          icon: const Icon(HMIcons.houseFill),
          onPressed: () => router.go('/'),
        ),
      ],
      body: Column(
        children: [
          HosTabBar(
            tabs: listTabs.map((t) => t.label).toList(),
            icons: listTabs.map((t) => t.icon!).toList(),
            selectedIndex: selectedTabIndex.value,
            onChanged: (i) {
              selectedTabIndex.value = i;
              pageController.value.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          Expanded(
            child: PageView(
              controller: pageController.value,
              onPageChanged: (i) => selectedTabIndex.value = i,
              children: listTabs
                  .map((tab) => RustDailyListTab(key: ValueKey(tab.key), tab: tab))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

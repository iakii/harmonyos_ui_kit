// ignore_for_file: avoid_print

import 'package:bootscrap_icons/bootscrap_icons.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/counter_provider.dart';

/// HarmonyOS UI 组件展示页面。
///
/// 使用 [HookConsumerWidget]：count 由 Riverpod 管理，UI 本地状态由 flutter_hooks 管理。
class HarmonyOSPage extends HookConsumerWidget {
  const HarmonyOSPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // === Riverpod 管理的全局状态 ===
    final counter = ref.watch(counterProvider);
    final counterNotifier = ref.read(counterProvider.notifier);

    // === flutter_hooks 管理的本地 UI 状态 ===
    final isChecked = useState(false);
    final isOn = useState(false);
    final sliderVal = useState(0.5);
    final rating = useState(3.5);
    final selectedTabIndex = useState(0);
    final formKey = useState(GlobalKey<FormState>());

    return HosPage(
      title: title,
      showAppBar: false,
      leading: const Icon(Icons.menu),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const HosDivider(label: 'OR'),
            Icon(BTIcons.house),
            Icon(HMIcons.harmonyos),
            Icon(HMIcons.heartFill),
            Icon(HMIcons.starFill),
            Icon(HMIcons.trash),

            // JS 解析页面入口
            const SizedBox(height: 12),
            // 设置项
            HosInfoLabel(
              label: 'Dark mode',
              info: '说明',
              child: HosSwitch(
                checked: isOn.value,
                onChanged: (v) => isOn.value = v,
              ),
            ),

            const Text('You have pushed the button this many times:'),
            Text('$counter'),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: HosButton(
                onPressed: () async {
                  counterNotifier.increment();
                },
                child: const Text('确认'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: HosOutlinedButton(
                onPressed: () {},
                child: const Text('取消'),
              ),
            ),

            // 复选框
            HosCheckbox(
              checked: isChecked.value,
              onChanged: (v) => isChecked.value = v,
            ),

            // 开关
            HosSwitch(checked: isOn.value, onChanged: (v) => isOn.value = v),

            // 滑块
            HosSlider(
              value: sliderVal.value,
              min: 0,
              max: 1,
              onChanged: (v) => sliderVal.value = v,
            ),

            // 评分
            HosRatingBar(
              rating: rating.value,
              maxRating: 5,
              onChanged: (v) => rating.value = v,
            ),

            // 文本输入
            HosTextInput(placeholder: 'Enter name', onChanged: (v) => print(v)),
            const HosLoading(),
            HosEmptyState(
              icon: Icons.error_outline,
              title: 'No Data',
              message: 'There is no data to display.',
              action: HosButton(onPressed: () {}, child: const Text('Retry')),
            ),
            HosProgressBar(value: 0.7),
            HosCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const Text('This is a card description.'),
                  ],
                ),
              ),
            ),

            HosTabBar(
              tabs: const ['Tab A', 'Tab B', 'Tab C', 'Tab D', 'Tab E'],
              icons: const [
                Icons.home,
                Icons.search,
                Icons.notifications,
                Icons.person,
                Icons.settings,
              ],
              selectedIndex: selectedTabIndex.value,
              onChanged: (i) => selectedTabIndex.value = i,
            ),

            // 搜索框
            HosSearchBox(
              placeholder: 'Search...',
              onSubmitted: (v) => {print('Search submitted: $v')},
            ),

            // 密码输入
            HosPasswordInput(
              placeholder: 'Password',
              onChanged: (v) => print(v),
            ),

            // 表单（带验证）
            Form(
              key: formKey.value,
              child: HosTextFormInput(
                placeholder: 'Email',
                validator: (v) =>
                    v?.contains('@') == true ? null : 'Invalid email',
              ),
            ),

            HosErrorState(
              message: 'Failed to load',
              onRetry: () {
                final cancel = HosLoading.show(context);

                Future.delayed(const Duration(seconds: 2), () {
                  cancel();
                });
              },
            ),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  HosNavigationRail(
                    items: [
                      HosNavRailItem(icon: Icons.home, label: 'Home'),
                      HosNavRailItem(icon: Icons.settings, label: 'Settings'),
                    ],
                    selectedIndex: 0,
                    onChanged: (i) {
                      showHosDialog(
                        context: context,
                        title: 'Confirm',
                        content: 'Are you sure?',
                        actions: [
                          HosDialogButton(
                            'Cancel',
                            onTap: () => Navigator.pop(context, false),
                          ),
                          HosDialogButton(
                            'OK',
                            isPrimary: true,
                            onTap: () => Navigator.pop(context, true),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            HosButton(
              onPressed: () => context.push('/js_parse'),
              child: const Text('JS 解析'),
            ),

            Image.network(
              'https://cdn.pixabay.com/photo/2026/06/08/10/34/10-34-35-885_1280.jpg',
            ),
            Image.network(
              'https://cdn.pixabay.com/photo/2025/05/02/15/58/flower-girl-9574211_1280.jpg',
            ),
            Image.network(
              'https://cdn.pixabay.com/photo/2016/05/31/11/26/baby-1426651_1280.jpg',
            ),

            const SizedBox(height: 128),
          ],
        ),
      ),
      // floatingActionButton: HosIconButton(
      //   onPressed: () => counterNotifier.increment(),
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

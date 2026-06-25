// ignore_for_file: avoid_print

import 'package:flutter/material.dart' show Colors, Icons, TimeOfDay;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/router.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';
import 'package:styled_widget/styled_widget.dart';

/// HarmonyOS UI 组件展示页面。
///
/// 按目录分组展示 packages/harmonyos_ui 的全部组件。
class HarmonyOSPage extends HookConsumerWidget {
  const HarmonyOSPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- 交互状态 ---
    final isChecked = useState(false);
    final isOn = useState(false);
    final sliderVal = useState(0.5);
    final rating = useState(3.5);
    final radioSelected = useState(0); // 0 or 1
    final tabIndex = useState(0);
    final bottomNavIndex = useState(0);
    final navRailIndex = useState(0);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return HosPage(
      title: title,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ==================== Buttons ====================
          _sectionHeader(context, 'Buttons', '按钮'),
          const SizedBox(height: 12),
          HosButton(
            onPressed: () =>
                showHosToast(context: context, message: 'HosButton 点击'),
            child: const Text('HosButton'),
          ),
          const SizedBox(height: 8),
          HosOutlinedButton(
            onPressed: () =>
                showHosToast(context: context, message: 'Outlined'),
            child: const Text('HosOutlinedButton'),
          ),
          const SizedBox(height: 8),
          HosTextButton(
            onPressed: () => showHosToast(context: context, message: 'Text'),
            child: const Text('HosTextButton'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HosIconButton(
                onPressed: () => print('icon'),
                child: const Icon(Icons.star),
              ),
              const SizedBox(width: 8),
              HosIconButton(
                onPressed: () => print('icon'),
                child: const Icon(Icons.favorite),
              ),
              const SizedBox(width: 8),
              HosIconButton(
                onPressed: () => print('icon'),
                child: const Icon(Icons.share),
              ),
            ],
          ),

          // ==================== Inputs ====================
          _sectionHeader(context, 'Inputs', '输入控件'),
          const SizedBox(height: 12),
          HosCheckbox(
            checked: isChecked.value,
            onChanged: (v) => isChecked.value = v,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              HosRadio(
                selected: radioSelected.value == 0,
                onChanged: () => radioSelected.value = 0,
              ),
              HosRadio(
                selected: radioSelected.value == 1,
                onChanged: () => radioSelected.value = 1,
              ),
            ],
          ),
          const SizedBox(height: 8),
          HosInfoLabel(
            label: 'HosSwitch',
            child: HosSwitch(
              checked: isOn.value,
              onChanged: (v) => isOn.value = v,
            ),
          ),
          const SizedBox(height: 8),
          HosInfoLabel(
            label: 'HosSlider',
            child: SizedBox(
              width: 200,
              child: HosSlider(
                value: sliderVal.value,
                min: 0,
                max: 1,
                onChanged: (v) => sliderVal.value = v,
              ),
            ),
          ),
          const SizedBox(height: 8),
          HosRatingBar(
            rating: rating.value,
            maxRating: 5,
            onChanged: (v) => rating.value = v,
          ),

          // ==================== Form Fields ====================
          _sectionHeader(context, 'Form Fields', '表单字段'),
          const SizedBox(height: 12),
          HosTextInput(
            placeholder: 'HosTextInput — 输入文本',
            onChanged: (v) => print('text: $v'),
          ),
          const SizedBox(height: 8),
          HosSearchBox(
            placeholder: 'HosSearchBox — 搜索…',
            onSubmitted: (v) => print('search: $v'),
          ),
          const SizedBox(height: 8),
          HosPasswordInput(
            placeholder: 'HosPasswordInput — 密码',
            onChanged: (v) => print('password: $v'),
          ),
          const SizedBox(height: 8),
          Form(
            key: formKey,
            child: HosTextFormInput(
              placeholder: 'HosTextFormInput — 邮箱（带校验）',
              validator: (v) => v?.contains('@') == true ? null : '请输入有效邮箱',
            ),
          ),

          // ==================== Navigation ====================
          _sectionHeader(context, 'Navigation', '导航'),
          const SizedBox(height: 12),
          _label(context, 'HosAppBar + BackIcon'),
          const SizedBox(height: 4),
          const BackIcon(),
          const SizedBox(height: 12),
          _label(context, 'HosTabBar'),
          const SizedBox(height: 4),
          HosTabBar(
            tabs: const ['首页', '发现', '消息', '我的'],
            icons: const [
              Icons.home,
              Icons.explore,
              Icons.notifications,
              Icons.person,
            ],
            selectedIndex: tabIndex.value,
            onChanged: (i) => tabIndex.value = i,
          ),
          const SizedBox(height: 12),
          _label(context, 'HosBottomNavigation'),
          const SizedBox(height: 4),

          Container(
            decoration: BoxDecoration(
              color: HarmonyTheme.of(context).surfaceColor,
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 254, 148, 148),
                  const Color.fromARGB(255, 255, 221, 221),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 128,
                  child: HosBottomNavigation(
                    floating: true,
                    items: const [
                      HosBottomNavItem(icon: Icons.home, label: '首页'),
                      HosBottomNavItem(icon: Icons.settings, label: '设置'),
                      HosBottomNavItem(icon: Icons.person, label: '我的'),
                    ],
                    selectedIndex: bottomNavIndex.value,
                    onChanged: (i) => bottomNavIndex.value = i,
                  ),
                ),
                SizedBox(
                  height: 86,
                  child: HosBottomNavigation(
                    items: const [
                      HosBottomNavItem(icon: Icons.home, label: '首页'),
                      HosBottomNavItem(icon: Icons.settings, label: '设置'),
                      HosBottomNavItem(icon: Icons.person, label: '我的'),
                    ],
                    selectedIndex: bottomNavIndex.value,
                    onChanged: (i) => bottomNavIndex.value = i,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _label(context, 'HosNavigationRail'),
          const SizedBox(height: 4),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                HosNavigationRail(
                  items: const [
                    HosNavRailItem(icon: Icons.home, label: 'Home'),
                    HosNavRailItem(icon: Icons.settings, label: 'Settings'),
                    HosNavRailItem(icon: Icons.info, label: 'About'),
                  ],
                  selectedIndex: navRailIndex.value,
                  onChanged: (i) => navRailIndex.value = i,
                ),

                Expanded(
                  child: Center(
                    child: Text(
                      '当前选中：${['Home', 'Settings', 'About'][navRailIndex.value]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================== Surfaces ====================
          _sectionHeader(context, 'Surfaces', '表面'),
          const SizedBox(height: 12),
          _label(context, 'HosCard'),
          const SizedBox(height: 4),
          HosCard(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('卡片标题', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('这是一段卡片描述文字，用于展示 HosCard 组件。'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HosButton(
                onPressed: () async {
                  final cancel = await showHosDialog<bool>(
                    context: context,
                    title: '确认操作',
                    content: '确定要执行此操作吗？',
                    actions: [
                      HosDialogButton(
                        '取消',
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop(false);
                        },
                      ),
                      HosDialogButton(
                        '确定',
                        isPrimary: true,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop(true);
                        },
                      ),
                    ],
                  );

                  if (context.mounted) {
                    showHosToast(
                      context: context,
                      message: 'showHosDialog 返回值：${cancel.toString()}',
                    );
                  }
                },
                child: const Text('showHosDialog'),
              ),
              HosOutlinedButton(
                onPressed: () => showHosToast(
                  context: context,
                  message: 'showHosToast — 操作成功',
                ),
                child: const Text('showHosToast'),
              ),
              HosTextButton(
                onPressed: () => showHosBottomSheet(
                  context: context,
                  title: 'Bottom Sheet',
                  builder: (ctx) => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('showHosBottomSheet 内容区域'),
                  ),
                ),
                child: const Text('showHosBottomSheet'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label(context, 'HosLoading'),
          const SizedBox(height: 4),
          const Loading(size: 64),
          const SizedBox(height: 12),
          _label(context, 'HosProgressBar / HosProgressRing'),
          const SizedBox(height: 4),
          HosProgressBar(value: 0.7),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              height: 48,
              width: 48,
              child: const HosProgressRing(size: 40, value: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          _label(context, 'HosListItem'),
          const SizedBox(height: 4),
          HosListItem(
            leading: const Icon(Icons.person),
            title: '用户名称',
            subtitle: '在线',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => print('list item tapped'),
          ),
          HosListItem(
            leading: const Icon(Icons.settings),
            title: '设置',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => print('settings tapped'),
          ),
          HosListItem(
            leading: const Icon(Icons.info),
            title: '关于',
            subtitle: 'v1.0.0',
            onTap: () => print('about tapped'),
          ),
          const SizedBox(height: 12),
          HosEmptyState(
            icon: Icons.inbox,
            title: 'HosEmptyState',
            message: '暂无数据，请稍后再试。',
            action: HosButton(onPressed: () {}, child: const Text('刷新')),
          ),
          const SizedBox(height: 8),
          HosErrorState(
            message: 'HosErrorState — 加载失败',
            onRetry: () {
              final cancel = HosLoading.show(context);
              Future.delayed(const Duration(seconds: 2), cancel);
            },
          ),

          // ==================== Pickers ====================
          _sectionHeader(context, 'Pickers', '选择器'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HosButton(
                onPressed: () async {
                  final date = await showHosDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null && context.mounted) {
                    showHosToast(
                      context: context,
                      message:
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                    );
                  }
                },
                child: const Text('showHosDatePicker'),
              ),
              HosOutlinedButton(
                onPressed: () async {
                  final time = await showHosTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null && context.mounted) {
                    showHosToast(
                      context: context,
                      message: time.format(context),
                    );
                  }
                },
                child: const Text('showHosTimePicker'),
              ),
            ],
          ),

          // ==================== Utils ====================
          _sectionHeader(context, 'Utils', '工具'),
          const SizedBox(height: 12),
          _label(context, 'HosDivider'),
          const SizedBox(height: 4),
          const HosDivider(),
          const SizedBox(height: 8),
          const HosDivider(label: '带文字分割线'),
          const SizedBox(height: 12),
          _label(context, 'HosInfoLabel'),
          const SizedBox(height: 4),
          HosInfoLabel(
            label: '标签',
            info: 'hover 查看说明',
            child: const Text('内容区域'),
          ),
          const SizedBox(height: 12),
          _label(context, 'HosFocusBorder'),
          const SizedBox(height: 4),
          const HosFocusBorder(
            autofocus: true,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('聚焦边框（点击获取焦点）'),
            ),
          ),

          // ==================== Icons ====================
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _sectionHeader(context, 'HMIcons', '图标示例').expanded(),
              HosTextButton(
                child: Text('更多'),
                onPressed: () => router.go('/icons'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              const Icon(HMIcons.harmonyos, size: 28),
              const Icon(HMIcons.heartFill, size: 28),
              const Icon(HMIcons.starFill, size: 28),
              const Icon(HMIcons.trash, size: 28),
              const Icon(HMIcons.artGallery, size: 28),
            ],
          ),

          const SizedBox(height: 128),
        ],
      ),
    );
  }

  /// 分组标题，带中英文和分割线。
  Widget _sectionHeader(BuildContext context, String en, String zh) {
    final theme = HarmonyTheme.of(context);
    final separator = Container(height: 1, color: theme.dividerColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(children: [Expanded(child: separator)]),
        const SizedBox(height: 16),
        Text(
          '$en  ·  $zh',
          style: theme.typography.title2?.copyWith(color: theme.accentColor),
        ),
        const SizedBox(height: 4),
        separator,
      ],
    );
  }

  /// 小标签说明。
  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    );
  }
}

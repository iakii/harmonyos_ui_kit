import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useState;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/providers/js/config_provider.dart';
import 'package:rohos_app/providers/js/settings_provider.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:styled_widget/styled_widget.dart';

class SettingPanel extends HookConsumerWidget {
  const SettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(jsConfigProvider.future);

    final theme = HarmonyTheme.of(context);

    final defaultItem = ref.watch(jsSourceProvider);
    final defaultAssets = useState(defaultItem);

    return SafeArea(
      child: Scaffold(
        appBar: HosAppBar(
          height: 56,
          backgroundColor: HarmonyTheme.of(context).surfaceColor,
          title: '设置',
          leading: SizedBox.shrink(),
        ),
        body: FutureBuilder(
          future: config,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (asyncSnapshot.hasError) {
              return Center(child: Text('加载配置失败: ${asyncSnapshot.error}'));
            } else if (!asyncSnapshot.hasData) {
              return Center(child: Text('未获取到配置数据'));
            }
            final jsConfig = asyncSnapshot.data!;

            return ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: jsConfig.sites.length,
              itemBuilder: (BuildContext context, int index) {
                final item = jsConfig.sites[index];
                return Row(
                      children: [
                        SizedBox(width: 12),
                        Text(
                              (item.title).substring(0, 1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            )
                            .fontFamily('HarmonyOs Sans SC')
                            .center()
                            .width(36)
                            .height(36)
                            .backgroundColor(theme.accentColor)
                            .clipRRect(all: 12),
                        SizedBox(width: 12),
                        Text(item.title)
                            .fontSize(14)
                            .fontWeight(FontWeight.bold)
                            .fontFamily('HarmonyOs Sans SC')
                            .expanded(),

                        HosRadio(
                          selected: defaultAssets.value == item.assets,
                          onChanged: () {
                            defaultAssets.value = item.assets;
                          },
                        ),
                        SizedBox(width: 12),
                      ],
                    )
                    .padding(vertical: 8)
                    .ripple()
                    .backgroundColor(theme.surfaceColor)
                    .clipRRect(all: 12)
                    .gestures(
                      onTap: () {
                        defaultAssets.value = item.assets;
                      },
                    );
              },
              separatorBuilder: (BuildContext context, int index) {
                return SizedBox(height: 12);
              },
            );
          },
        ),
        bottomNavigationBar: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: HosButton(
                    child: Center(child: Text('确定')),
                    onPressed: () {
                      ref
                          .read(jsSourceProvider.notifier)
                          .set(defaultAssets.value ?? '');
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      router.go('/js_gallery');
                    },
                  ),
                ),
                SizedBox(width: 8),
                HosOutlinedButton(
                  child: Center(child: Text('清除')),
                  onPressed: () {
                    ref.read(jsSourceProvider.notifier).clear();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

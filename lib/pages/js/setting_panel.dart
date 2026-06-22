import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' show useState;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/providers/js/settings_provider.dart';
import 'package:rohos_app/services/date.dart';
import 'package:styled_widget/styled_widget.dart';

class SettingPanel extends HookConsumerWidget {
  const SettingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      {'title': '美图乐', 'assets': "assets/js/meitule.cjs"},
      {'title': 'Kaizty', 'assets': "assets/js/kaizty.cjs"},
    ];

    final theme = HarmonyTheme.of(context);

    final defaultItem = ref.watch(jsSourceProvider);
    final defaultAssets = useState(defaultItem);

    return SafeArea(
      child: Scaffold(
        appBar: HosAppBar(
          backgroundColor: HarmonyTheme.of(context).surfaceColor,
          title: '设置',
          leading: SizedBox.shrink(),
        ),
        body: ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: items.length,

          itemBuilder: (BuildContext context, int index) {
            final item = items[index];
            return Row(
                  children: [
                    SizedBox(width: 12),
                    Text(
                          (item['title'] ?? "${index + 1}").substring(0, 1),
                          style: TextStyle(color: Colors.white, fontSize: 23),
                        )
                        .fontFamily('HarmonyOs Sans SC')
                        .center()
                        .width(66)
                        .height(66)
                        .backgroundColor(theme.accentColor)
                        .clipRRect(all: 12),
                    SizedBox(width: 12),
                    Text(item['title'] ?? '')
                        .fontSize(24)
                        .fontWeight(FontWeight.bold)
                        .fontFamily('HarmonyOs Sans SC')
                        .expanded(),

                    HosRadio(
                      selected: defaultAssets.value == item['assets'],
                      onChanged: () {
                        defaultAssets.value = item['assets'];
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
                    defaultAssets.value = item['assets'];
                  },
                );
          },
          separatorBuilder: (BuildContext context, int index) {
            return SizedBox(height: 12);
          },
        ),
        bottomNavigationBar: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HosButton(
              child: Center(child: Text('确定')),
              onPressed: () {
                ref
                    .read(jsSourceProvider.notifier)
                    .set(defaultAssets.value ?? '');
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/presentation/providers/rust_daily/rust_daily_provider.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/presentation/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/presentation/widgets/loading.dart';

/// Rust Daily 文章详情页。
///
/// 接收文章 [url] 和 [title]，通过 [rustDailyProvider] 获取 HTML 内容并渲染。
class RustDailyDetailPage extends HookConsumerWidget {
  const RustDailyDetailPage({
    super.key,
    required this.url,
    this.title = '',
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = RustDailyParams(url: url, type: 'detail', page: 1);

    final asyncData = ref.watch(rustDailyProvider(params));

    final html = asyncData.valueOrNull?.html ?? '';

    return HosPage(
      title: title,
      showAppBar: true,
      leading: const BackIcon(),
      actions: [
        IconButton(
          icon: const Icon(HMIcons.houseFill),
          onPressed: () => router.go('/'),
        ),
      ],
      body: asyncData.isLoading && html.isEmpty
          ? const Center(child: Loading(size: 64))
          : asyncData.hasError && html.isEmpty
              ? HosErrorState(
                  message: asyncData.error.toString(),
                  onRetry: () => ref.invalidate(rustDailyProvider(params)),
                )
              : ScrollConfiguration(
                  behavior: const ScrollBehavior(),
                  child: ListView(
                    children: [
                      HtmlWidget(
                        html,
                        textStyle: const TextStyle(fontSize: 15),
                        onTapUrl: (_) => true,
                        onLoadingBuilder:
                            (context, element, loadingProgress) =>
                                const Loading(size: 64),
                        customWidgetBuilder: customWidgetBuilder,
                      ),
                      const SizedBox(height: 128),
                    ],
                  ),
                ),
    );
  }
}

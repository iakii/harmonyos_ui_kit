import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/presentation/providers/rust_daily/rust_daily_provider.dart';
import 'package:rohos_app/presentation/widgets/scrollbar.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/presentation/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/presentation/widgets/loading.dart';

/// Rust Daily 文章详情页。
///
/// 接收文章 [url] 和 [title]，通过 [rustDailyProvider] 获取 HTML 内容并渲染。
class RustDailyDetailPage extends ConsumerStatefulWidget {
  const RustDailyDetailPage({super.key, required this.url, this.title = ''});

  final String url;
  final String title;

  @override
  ConsumerState<RustDailyDetailPage> createState() =>
      _RustDailyDetailPageState();
}

class _RustDailyDetailPageState extends ConsumerState<RustDailyDetailPage> {
  @override
  void initState() {
    super.initState();
    // 预加载数据
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final p = RustDailyParams(url: widget.url, type: 'detail');
      ref.read(rustDailyProvider(p).notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = RustDailyParams(url: widget.url, type: 'detail');
    final html = ref.watch(
      rustDailyProvider(params).select((value) => value.html),
    );
    final isLoading = ref.watch(
      rustDailyProvider(params).select((value) => value.loading),
    );

    return HosPage(
      title: widget.title,
      showAppBar: true,
      leading: const BackIcon(),
      actions: [
        IconButton(
          icon: const Icon(HMIcons.houseFill),
          onPressed: () => router.go('/'),
        ),
      ],
      body: isLoading && html.isEmpty
          ? const Center(child: Loading(size: 64))
          : ScrollConfiguration(
              behavior: const CustomScrollBehaviour(),
              child: ListView(
                children: [
                  HtmlWidget(
                    html,
                    textStyle: const TextStyle(fontSize: 15),
                    onLoadingBuilder: (context, element, loadingProgress) =>
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

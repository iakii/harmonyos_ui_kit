import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/providers/dio_provider.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/widgets/loading.dart';
import 'package:rohos_app/widgets/scrollbar.dart' show CustomScrollBehaviour;

class RustDailyPage extends ConsumerStatefulWidget {
  const RustDailyPage({
    super.key,
    this.url =
        "https://rustcc.cn/section?id=f4703117-7e6b-4caf-aa22-a3ad3db6898f",
  });
  final String? url;

  @override
  ConsumerState<RustDailyPage> createState() => _RustDailyPageState();
}

class _RustDailyPageState extends ConsumerState<RustDailyPage> {
  late final JsEngine engine;

  @override
  void initState() {
    initEngine();
    super.initState();
  }

  initEngine() async {
    runCode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final _controller = ScrollController();
  String kHtml = '';

  final host = "https://rustcc.cn";

  Future<void> runCode() async {
    if (widget.url == null || widget.url!.isEmpty) {
      return;
    }
    final dio = ref.read(dioClientProvider).dio;
    final url = widget.url!.startsWith("http")
        ? widget.url!
        : "$host${widget.url}";
    dio
        .get(url)
        .then((response) {
          if (response.statusCode == 200) {
            setState(() {
              kHtml =
                  '''
<div style="padding:16px">
${response.data}
</div>
''';
            });
          } else {
            debugPrint('Failed to load HTML: ${response.statusCode}');
          }
        })
        .catchError((error) {
          debugPrint('Error fetching HTML: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    // final theme = HarmonyTheme.of(context);
    return HosPage(
      title: 'Rust Daily',
      showAppBar: true,
      extendBodyBehindAppBar: true,
      leading: Navigator.of(context).canPop()
          ? BackIcon()
          : Icon(HMIcons.harmonyos, size: 30),
      actions: [
        IconButton(
          icon: const Icon(HMIcons.houseFill),
          onPressed: () => router.go('/'),
        ),
      ],
      body: ScrollConfiguration(
        behavior: CustomScrollBehaviour(),
        child: ListView(
          controller: _controller,
          children: [
            kHtml.isEmpty
                ? Center(child: const Loading(size: 64))
                : HtmlWidget(
                    kHtml,
                    textStyle: TextStyle(
                      fontSize: 15,
                      // height: 1.5,
                      // color: theme.accentColor,
                    ),
                    onTapUrl: (url) {
                      debugPrint('onTapUrl: $url');
                      router.push('/rust', extra: url);
                      return true;
                    },
                    onLoadingBuilder: (context, element, loadingProgress) =>
                        const Loading(size: 64),
                    customWidgetBuilder: customWidgetBuilder,
                  ),

            SizedBox(height: 128),
          ],
        ),
      ),
    );
  }
}

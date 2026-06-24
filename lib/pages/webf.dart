import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/widgets/loading.dart';
import 'package:rohos_app/widgets/scrollbar.dart' show CustomScrollBehaviour;

class WebFPage extends StatefulWidget {
  const WebFPage({super.key});

  @override
  State<WebFPage> createState() => _WebFPageState();
}

class _WebFPageState extends State<WebFPage> {
  late final JsEngine engine;
  Map<String, dynamic> _info = {};
  List<Map<String, String>> _menus = [];
  int _currentMenuIndex = 0;

  @override
  void initState() {
    initEngine();
    super.initState();
  }

  initEngine() async {
    final code = await rootBundle.loadString('assets/views/hadaka.js');
    engine = JsEngine.create(
      runtimeOptions: JsRuntimeOptions(
        builtins: JsBuiltinOptions.all(), // Console + Fetch
        info: 'test',
      ),
      modules: [JsModule(name: 'client', source: code)],
    );

    runCode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    engine.close();
    _controller.dispose();
    super.dispose();
  }

  final _controller = ScrollController();
  String kHtml = '';

  /// 递归格式化 [JsValue] 为可读字符串。
  String fmtVal(JsValue v) => v.when(
    none: () => 'null',
    boolean: (b) => b.toString(),
    integer: (i) => i.toString(),
    float: (f) => f.toString(),
    bigInt: (s) => s,
    string: (s) => s,
    bytes: (b) => '<bytes: ${b.length} bytes>',
    array: (arr) => '[${arr.map(fmtVal).join(', ')}]',
    object: (obj) =>
        '{${obj.map((e) => '${e.$1}: ${fmtVal(e.$2)}').join(', ')}}',
    date: (d) =>
        DateTime.fromMillisecondsSinceEpoch(d.toInt()).toIso8601String(),
    symbol: (s) => 'Symbol($s)',
  );

  Future<void> runCode() async {
    try {
      // 构造请求 URL：首次调用使用默认值，后续使用解析后的 info
      final website = _info['website'] as String? ?? 'https://legs.a-hadaka.jp';
      final menu = _currentMenuIndex < _menus.length
          ? _menus[_currentMenuIndex]
          : null;
      final path = menu?['value'] ?? menu?['path'] ?? '/';
      final url = '$website$path';
      final page = _currentMenuIndex + 1;
      final output = await engine.eval(
        code:
            """
            (async function() {
                const {default:client} = await import('client');
                const info = JSON.parse(client.info);
                const html = await client.render('$url', $page);
                return JSON.stringify({info: info, html: html});
            })()
        """,
      );
      final result = jsonDecode(fmtVal(output));

      setState(() {
        if (result case {'info': final Map<String, dynamic> info}) {
          _info = info;
          _menus =
              (info['menus'] as List?)
                  ?.map((e) => Map<String, String>.from(e as Map))
                  .toList() ??
              [];
        }
        kHtml = result['html'] as String? ?? '';
      });

      debugPrint('runCode: html length = ${kHtml.length}, menus = $_menus');
    } on JsError catch (e) {
      final isCancelled = e.whenOrNull(cancelled: (_) => true) ?? false;
      if (isCancelled) return;
      debugPrint('runCode: JsError: $e');
    } catch (e) {
      debugPrint('runCode: error: $e');
    }
  }

  Future<void> _onMenuTap(int index) async {
    if (index == _currentMenuIndex) return;
    setState(() {
      _currentMenuIndex = index;
      kHtml = ''; // 切菜单时先清空内容，显示 Loading
    });
    await runCode();
  }

  @override
  Widget build(BuildContext context) {
    final title = _info['title'] as String? ?? 'WebF Page';
    return HosPage(
      title: title,
      showAppBar: true,
      actions: [
        IconButton(
          icon: const Icon(HMIcons.figureRun),
          onPressed: () async {
            runCode();
          },
        ),
      ],
      body: Column(
        children: [
          // 菜单导航标签
          if (_menus.isNotEmpty)
            HosTabBar(
              tabs: _menus.map((m) => m['label'] as String).toList(),
              selectedIndex: _currentMenuIndex,
              onChanged: _onMenuTap,
            ),

          Expanded(
            child: ScrollConfiguration(
              behavior: CustomScrollBehaviour(),
              child: SingleChildScrollView(
                controller: _controller,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: kHtml.isEmpty
                      ? Center(child: const Loading())
                      : HtmlWidget(
                          kHtml,
                          customWidgetBuilder: customWidgetBuilder,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/router.dart' show router;
import 'package:rohos_app/widgets/html/custom_widget_builder.dart'
    show customWidgetBuilder;
import 'package:rohos_app/widgets/loading.dart';
import 'package:rohos_app/widgets/scrollbar.dart' show CustomScrollBehaviour;

import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:styled_widget/styled_widget.dart';

class DynamicHtml2ViewPage extends StatefulWidget {
  const DynamicHtml2ViewPage({super.key});

  @override
  State<DynamicHtml2ViewPage> createState() => _DynamicHtml2ViewPageState();
}

class _DynamicHtml2ViewPageState extends State<DynamicHtml2ViewPage> {
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
    _codeController.fullText = code;
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
  // String code = '';

  final _codeController = CodeController(
    text: '...', // Initial code
    language: javascript,
  );

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
      leading: Icon(HMIcons.harmonyos, size: 30),
      actions: [
        IconButton(
          icon: const Icon(HMIcons.houseFill),
          onPressed: () => router.go('/'),
        ),

        IconButton(
          icon: const Icon(HMIcons.code),
          onPressed: () async {
            showHosBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) {
                return ListView(
                  // padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'HTML 内容',
                    ).fontSize(18).fontWeight(FontWeight.bold).padding(all: 16),
                    CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          // lineNumbers: false,
                          gutterStyle: GutterStyle(margin: 0),
                          wrap: true,
                          controller: _codeController,
                          textStyle: const TextStyle(
                            fontFamily: 'SourceCodePro',
                            fontSize: 12,
                          ),
                          // expands: true,
                          readOnly: true,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
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
              child: ListView(
                controller: _controller,
                children: [
                  kHtml.isEmpty
                      ? Center(child: const Loading())
                      : HtmlWidget(
                          kHtml,
                          customWidgetBuilder: customWidgetBuilder,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

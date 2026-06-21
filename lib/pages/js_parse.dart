import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:logger/logger.dart' show Logger;
import 'package:signals/signals_flutter.dart';

/// JS 解析页面 —— 展示 js_runtime 的 JavaScript 执行能力。
///
/// 使用 [signals] 进行状态管理，替代 hooks + riverpod。
class JsParsePage extends StatefulWidget {
  const JsParsePage({super.key});

  @override
  State<JsParsePage> createState() => _JsParsePageState();
}

class _JsParsePageState extends State<JsParsePage> {
  // ─── Controllers ────────────────────────────────────────────
  final codeController = TextEditingController(
    text: '''
// 👇 meitule.js 图集解析示例
(async function() {
    const { default: client } = await import('client');

    // 1. 获取插件信息（pluginInfo 是 getter，返回 JSON 字符串）
    const info = JSON.parse(client.pluginInfo);
    console.log('插件名称:', info.name);

    // 通过 postMessage 将数据传给 Dart 端的 listData
    postMessage('pluginInfo', JSON.stringify(info));

    // 2. 解析 HTML 获取图片列表（离线测试）
    var mockHtml = '<a class="list-img" href="/photo/123.html"><img data-src="https://example.com/1.jpg" alt="写真集 A"></a>';
    mockHtml += '<li class="page-item"><a class="page-link" href="index_3.html"></a></li>';

    var totalPages = client.getPhotosPageSize(mockHtml);
    console.log('step:', 1);
    postMessage('pageSize', JSON.stringify({ totalPages: totalPages }));
 console.log('step:', 2);
    // 3. 在线获取图片列表（需要 JS 运行时支持 fetch）:
    var result = await client.getPage('https://www.meitula.org/', 1);
     console.log('step:', 3);
    postMessage('pageResult', result);
     console.log('step:', 4);

    // 4. 处理结果并回传给 Dart 端
    // const sumRes= await sum(1,2);
    // console.log('sum(1,2) =', sumRes);

    return JSON.stringify({ name: info.name, totalPages: totalPages });
})()
''',
  );

  // ─── Non-reactive（不需要响应式）───────────────────────────────
  late JsEngine _jsRuntime;

  // ─── Signals（响应式状态）─────────────────────────────────────
  final listData = signal<List<String>>([]);
  final isRunning = signal(false);
  final result = signal<String?>(null);
  final error = signal<String?>(null);
  final memInfo = signal('');
  final version = signal('');

  // ─── Formatters ──────────────────────────────────────────────

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

  /// 格式化字节为可读字符串。
  String fmtBytes(BigInt b) {
    final kb = BigInt.from(1024);
    final mb = BigInt.from(1024 * 1024);
    if (b < kb) return '$b B';
    if (b < mb) return '${(b / kb).toStringAsFixed(1)} KB';
    return '${(b / mb).toStringAsFixed(1)} MB';
  }

  // ─── Lifecycle ───────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initRuntime();
  }

  @override
  void dispose() {
    codeController.dispose();
    _jsRuntime.close();
    super.dispose();
  }

  late JsCallbackHandler handler;

  Future<void> _initRuntime() async {
    try {
      final jsFiles = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/js/meitule.js');

      _jsRuntime = JsEngine.create(
        runtimeOptions: JsRuntimeOptions(
          builtins: JsBuiltinOptions.all(),
          info: "parser=esbuild",
          // memoryLimit: BigInt.from(100 * 1024 * 1024),
        ),
        modules: [JsModule(name: 'client', source: jsFiles)],
      );

      handler = JsCallbackHandler(_jsRuntime);
      debugPrint('注册 postMessage 回调');
      // 直接传入 Dart 函数 —— 看起来就像直接注入
      handler.register('postMessage', (args) {
        debugPrint('Received from JS:  data=$args');
        final type = args[0].asStringSync ?? '';
        final data = args[1].asStringSync ?? '';
        if (type == 'sendChannelDetails') {
          debugPrint('Received from JS: type=$type, data=$data');
        }
        if (type == 'stopLoading') {
          debugPrint('Received stopLoading signal from JS');
        }
        return JsValue.none();
      });

      version.value = 'JsRuntime (built-in)';
    } catch (e) {
      Logger().e('Failed to initialize JS runtime', error: e);
      error.value = '初始化 JS 运行时失败: $e';
    }
  }

  // ─── Actions ─────────────────────────────────────────────────

  Future<void> runCode() async {
    final engine = _jsRuntime;

    final code = codeController.text.trim();
    if (code.isEmpty) {
      error.value = '请输入 JavaScript 代码';
      return;
    }

    isRunning.value = true;
    result.value = null;
    error.value = null;

    try {
      final output = await handler.eval(code);
      result.value = fmtVal(output);
      // 更新内存信息
      final used = engine.memoryUsage();
      final total = JsRuntime.totalMemoryUsage();
      memInfo.value = '估算: ${fmtBytes(used)} | 进程: ${fmtBytes(total)}';
    } catch (e) {
      error.value = e.toString();
    } finally {
      isRunning.value = false;
    }
  }

  void _releaseMemory() {
    final engine = _jsRuntime;
    // if (engine == null) return;
    engine.runGc();
    memInfo.value =
        '估算: ${fmtBytes(engine.memoryUsage())} | 进程: ${fmtBytes(JsRuntime.totalMemoryUsage())}';
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch 包裹的内容会在任意 signal 变化时自动重建
    return Watch((context) {
      final theme = HarmonyTheme.of(context);

      return HosPage(
        leading: const BackIcon(),
        title: 'JS 解析',
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 版本信息
              if (version.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(version.value, style: theme.typography.caption),
                ),

              // 内存信息
              if (memInfo.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          memInfo.value,
                          style: theme.typography.caption,
                        ),
                      ),
                      HosTextButton(
                        onPressed: _releaseMemory,
                        child: const Text('释放内存'),
                      ),
                    ],
                  ),
                ),

              // 代码输入区
              HosTextInput(
                controller: codeController,
                placeholder: '输入 JavaScript 代码',
                maxLines: 10,
                minLines: 10,
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 16),
              // 运行按钮
              HosButton(
                onPressed: isRunning.value ? null : runCode,
                child: isRunning.value
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('执行中...'),
                        ],
                      )
                    : const Text('运行'),
              ),

              // 错误提示
              if (error.value != null) ...[
                HosCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '错误',
                          style: TextStyle(
                            color: HarmonyColors.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          error.value!,
                          style: TextStyle(color: HarmonyColors.errorColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 执行结果
              if (result.value != null)
                HosCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '执行结果',
                          style: TextStyle(
                            color: theme.accentColor.normal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(result.value!),
                      ],
                    ),
                  ),
                ),

              // JS → Dart 消息列表（__postMessage 传递的数据）
              if (listData.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                HosCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'JS 消息 (listData)',
                              style: TextStyle(
                                color: theme.accentColor.normal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            HosTextButton(
                              onPressed: () => listData.value = [],
                              child: const Text('清空'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        ...listData.value.map(
                          (msg) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              msg,
                              style: theme.typography.caption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 128),
            ],
          ),
        ),
      );
    });
  }
}

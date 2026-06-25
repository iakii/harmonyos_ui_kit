import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:logger/logger.dart' show Logger;
import 'package:signals/signals_flutter.dart';

/// JS 解析页面 —— 展示 js_runtime 的 JavaScript 执行能力。
///
/// 使用 [signals] 进行状态管理，替代 hooks + riverpod。
class JsParsePage extends ConsumerStatefulWidget {
  const JsParsePage({super.key});

  @override
  ConsumerState<JsParsePage> createState() => _JsParsePageState();
}

class _JsParsePageState extends ConsumerState<JsParsePage> {
  // ─── Controllers ────────────────────────────────────────────
  final codeController = TextEditingController(
    text: '''
// 示例 JavaScript 代码
(async function(){
  const a = 1;
  const b = 2;
  // 发送消息给 Dart，会弹出通知
  showMessage(`Hello from JS! a=\${a}, b=\${b}`);
  // 发送请求
  const response = await fetch('https://jsonplaceholder.typicode.com/todos/1');
  const data = await response.json();
  showMessage(`Fetched data: \${JSON.stringify(data, null, 4)}`);

  // 解析dom示例
  const htmlString = '<div><p>Hello, <strong>World!</strong></p></div>';
  const dom= await import("dom");
  const pDom = dom.querySelector(htmlString, 'p');
  const p = JSON.parse(pDom);
  showMessage(`Parsed DOM: \${JSON.stringify(p, null, 4)}`);

  return JSON.stringify({a, b,'a+b':a+b, data, p, response:data}, null, 4);
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

  Future<void> _initRuntime() async {
    try {
      _jsRuntime = JsEngine.create(
        runtimeOptions: JsRuntimeOptions(
          builtins: JsBuiltinOptions.all(),
          info: "parser=esbuild",
        ),
      );

      await _jsRuntime.register(
        name: 'postMessage',
        func: (String argsJson) async {
          final args = jsonDecode(argsJson) as List;
          debugPrint('Received from JS:  data=$args');
          final type = args[0] as String? ?? '';
          final data = args[1] as String? ?? '';
          if (type == 'sendChannelDetails') {
            debugPrint('Received from JS: type=$type, data=$data');
          }
          if (type == 'stopLoading') {
            debugPrint('Received stopLoading signal from JS');
          }
          return jsonEncode(null);
        },
      );
      await _jsRuntime.register(
        name: 'showMessage',
        func: (String argsJson) async {
          final args = jsonDecode(argsJson) as List;
          debugPrint('Received from JS:  data=$args');
          final message = args[0] as String? ?? '';
          showHosToast(context: context, message: message);
          return jsonEncode(null);
        },
      );

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
      final output = await engine.eval(code: code);
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
        body: ListView(
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            // 错误提示
            if (error.value != null) ...[
              HosCard(
                margin: EdgeInsets.zero,
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
              const SizedBox(height: 12),
            ],

            // 执行结果
            if (result.value != null)
              HosCard(
                margin: EdgeInsets.zero,
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

            // JS → Dart 消息列表（__postMessage 传递的数据）
            if (listData.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              HosCard(
                margin: EdgeInsets.zero,
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
            ],
            const SizedBox(height: 128),
          ],
        ),
      );
    });
  }
}

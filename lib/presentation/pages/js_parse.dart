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
            // ExtendedImage.network(
            //   'https://img.xchina.io/photos/6a3d023474c78/00019.webp',

            //   headers: {
            //     ":authority": "img.xchina.io",
            //     ":method": "GET",
            //     ":path": "/photos/6a3d023474c78/00019.webp",
            //     ":scheme": "https",
            //     "accept":
            //         "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            //     "accept-encoding": "gzip, deflate, br, zstd",
            //     "accept-language": "zh-CN,zh;q=0.9",
            //     "cache-control": "no-cache",
            //     "cookie":
            //         "cf_clearance=LLKmzg3iZrGLRnza_itPMOzKmiyHO4YvYSVLWvTnTKo-1782611847-1.2.1.1-KePOLItM3BhH_yZWDngaHEatUlGcr8hvLNJYs8dkMEpEpIkrYDECkni8LHOjuo.KqO6vV_H3rsH6ov5DUEzKq6CiyVI_3nUgMemZ.H3RHao.SIVeEZuibMCRfkZRtX.U.4htNTokkofqXF6ZDNhQS18O2KvhVe4trg5XJ.bBpCQu_j.OhxnFgsPeWhYHqrlvzYUspQbmEyv6E0fnifvFGHLcJa80UfYlCW5BBo._MQOP.KfD0PKOj.jbs7Lg5IZDpaTlo6jbJhSz0x8a5kAtxEf5Xf_MFTJVp3CRyTTlwzxvRTW6T12tbgpVyVBqNqPBA11Eh1J9v7gdHlzr0KaRcVzAjU3RxJjRJkLDe9QYrif00wuNzjzcJoQWxxdPA8nXGUrhZnvajHct5Jd2Ofu1jQ5qEX_eAHNj3z1BNcDKAA_d0RinnlgFqwkbD7sMM0_.AihE_zebR4ro3Qn7jtVIA0UrEk6ULZTishR7o3bcSOPaYt2uuGvCKW1FQ6hsfCtx; cf_chl_rc_ni=1",
            //     "pragma": "no-cache",
            //     "priority": "u=0, i",
            //     "referer":
            //         "https://img.xchina.io/photos/6a3d023474c78/00019_600x0.webp",
            //     "sec-ch-ua":
            //         "\"Google Chrome\";v=\"149\", \"Chromium\";v=\"149\", \"Not)A;Brand\";v=\"24\"",
            //     "sec-ch-ua-arch": "\"x86\"",
            //     "sec-ch-ua-bitness": "\"64\"",
            //     "sec-ch-ua-full-version": "\"149.0.7827.201\"",
            //     "sec-ch-ua-full-version-list":
            //         "\"Google Chrome\";v=\"149.0.7827.201\", \"Chromium\";v=\"149.0.7827.201\", \"Not)A;Brand\";v=\"24.0.0.0\"",
            //     "sec-ch-ua-mobile": "?0",
            //     "sec-ch-ua-model": "\"\"",
            //     "sec-ch-ua-platform": "\"Windows\"",
            //     "sec-ch-ua-platform-version": "\"19.0.0\"",
            //     "sec-fetch-dest": "document",
            //     "sec-fetch-mode": "navigate",
            //     "sec-fetch-site": "same-origin",
            //     "sec-fetch-user": "?1",
            //     "upgrade-insecure-requests": "1",
            //     "user-agent":
            //         "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36",
            //   },
            //   loadStateChanged: imageLoadState,
            // ),

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

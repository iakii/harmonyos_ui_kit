import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:logger/logger.dart' show Logger;
import 'package:js_runtime/js_runtime.dart';
// import 'package:fjs/fjs.dart';

/// JS 解析页面 —— 展示 kossjs_flutter 的 JavaScript 执行能力。
///
/// 使用 [HookConsumerWidget]：KossJS 运行时由 hook 管理生命周期，UI 状态使用 useState。
class JsParsePage extends HookConsumerWidget {
  const JsParsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // === Hooks 管理本地状态 ===
    final codeController = useTextEditingController(
      text: '''
// 👇 动态 import() + DOM 解析 + fetch
(async function() {
    // 导入预加载的 math-utils 模块
    const math = await import('math-utils');
    console.log('math.add(3,4) =', math.add(3, 4));

    // 导入内置 DOM 模块（HTML 解析 + CSS 选择器）
    const dom = await import('dom');
    const html = '<div class="foo"><p id="msg">Hello World</p><p>bar</p></div>';
    const pTags = JSON.parse(dom.getElementsByTagName(html, 'p'));
    console.log('<p> count:', pTags.length);
    const msg = JSON.parse(dom.querySelector(html, '#msg'));
    console.log('#msg text:', msg.text);

    // 也可以使用 fetch 获取在线 HTML
    // var r = await fetch('https://example.com');
    // var html = await r.text();
    // var title = JSON.parse(dom.querySelector(html, 'title'));

    return 'math=' + math.multiply(6, 7) + ', pTags=' + pTags.length;
})()
''',
    );
    final runtime = useState<JsRuntime?>(null);
    final isRunning = useState(false);
    final result = useState<String?>(null);
    final error = useState<String?>(null);
    final memInfo = useState('');
    final version = useState('');

    /// 格式化字节为可读字符串
    String fmtBytes(BigInt b) {
      final kb = BigInt.from(1024);
      final mb = BigInt.from(1024 * 1024);
      if (b < kb) return '$b B';
      if (b < mb) return '${(b / kb).toStringAsFixed(1)} KB';
      return '${(b / mb).toStringAsFixed(1)} MB';
    }

    // Boa JS 运行时初始化（仅在组件挂载时执行一次）
    useEffect(() {
      Future<void> init() async {
        try {
          // 创建 Boa JS 运行时，设置 100MB 内存上限
          runtime.value = JsRuntime.create(
            options: JsRuntimeOptions(
              builtins: await JsBuiltinOptions.all(),
              info: "parser=esbuild",
              // memoryLimit: BigInt.from(100 * 1024 * 1024),
            ),
          );

          // 预加载一个 ES 模块
          runtime.value!.preloadModule(
            name: 'math-utils',
            source: '''
export function add(a, b) {
    console.log('add() called with', a, b);
    return a + b;
}
export function multiply(a, b) {
    return a * b;
}
''',
          );
          version.value = 'Boa (built-in)';
        } catch (e) {
          Logger().e('Failed to initialize JS runtime', error: e);
          error.value = '初始化 JS 运行时失败: $e';
        }
      }

      init();
      return () {
        runtime.value?.dispose();
      };
    }, const []);

    void runCode() {
      if (runtime.value == null) {
        error.value = 'JS 运行时未就绪';
        return;
      }

      final code = codeController.text.trim();
      if (code.isEmpty) {
        error.value = '请输入 JavaScript 代码';
        return;
      }

      isRunning.value = true;
      result.value = null;
      error.value = null;

      try {
        final output = runtime.value!.eval(code: code);
        result.value = output.asStringSync!;

        // 更新内存信息
        final used = runtime.value!.memoryUsage();
        final total = JsRuntime.totalMemoryUsage();
        memInfo.value = '估算: ${fmtBytes(used)} | 进程: ${fmtBytes(total)}';
      } catch (e) {
        error.value = e.toString();
      } finally {
        isRunning.value = false;
      }
    }

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
                child: Text(
                  version.value,
                  style: HarmonyTheme.of(context).typography.caption,
                ),
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
                        style: HarmonyTheme.of(context).typography.caption,
                      ),
                    ),
                    HosTextButton(
                      onPressed: () {
                        runtime.value?.releaseMemory();
                        final used = runtime.value!.memoryUsage();
                        final total = JsRuntime.totalMemoryUsage();
                        memInfo.value =
                            '估算: ${fmtBytes(used)} | 进程: ${fmtBytes(total)}';
                      },
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
                          color: HarmonyTheme.of(context).accentColor.normal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(result.value!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

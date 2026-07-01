import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jsf/jsf.dart';
import 'package:signals/signals_flutter.dart';

/// QuickJS 运行时 Demo 页面。
///
/// 使用 [jsf] 包（基于 QuickJS）的 JS 运行时能力展示。
/// 参考 JSF (https://github.com/moluopro/jsf) 的 API 设计。
///
/// 功能区域：
/// 1. 基础求值 —— eval() 直接返回 Dart 类型
/// 2. 类型与句柄 —— evalValue() 保留 JS 对象身份
/// 3. Dart 回调 —— registerFunction() JS 调用 Dart
/// 4. ES 模块 —— registerModules() 内存模块
/// 5. Promise / Async —— evalAsync() 自动 resolve
/// 6. 错误处理 —— JsException 捕获
/// 7. 初始化脚本 —— execInitScript() + call()
/// 8. 全局变量 —— setGlobal() / getGlobalValue()
class QuickJSPage extends ConsumerStatefulWidget {
  const QuickJSPage({super.key});

  @override
  ConsumerState<QuickJSPage> createState() => _QuickJSPageState();
}

class _QuickJSPageState extends ConsumerState<QuickJSPage> {
  // ─── JS Runtime ────────────────────────────────────────
  /// 可为 null：若构造函数失败则保持 null，避免 LateInitializationError。
  final JsRuntime _js = JsRuntime(
    options: const JsRuntimeOptions(
      memoryLimitBytes: 5 * 1024 * 1024, // 5MB
      // timeout: Duration(seconds: 5),
    ),
  );

  // ─── TextEditingControllers ────────────────────────────
  final _basicController = TextEditingController(text: '40 + 2');
  final _typeController = TextEditingController(
    text: '''({count: 2, items: [3, 4], name: 'test'})''',
  );
  final _callbackController = TextEditingController(text: 'dartSum(4, 5, 6)');
  final _moduleController = TextEditingController(
    text: '''import('math').then(m => m.add(10, 20))''',
  );
  final _promiseController = TextEditingController(
    text: '''new Promise((resolve) =>
  resolve('Hello from Promise!')
)''',
  );
  final _syntaxErrorController = TextEditingController(
    text: 'function test() { return ; }',
  );
  final _runtimeErrorController = TextEditingController(
    text: 'undefinedVar + 1',
  );
  final _scriptController = TextEditingController(
    text: '''function greet(name) {
  return 'Hello, ' + name + '!';
}''',
  );
  final _globalController = TextEditingController(text: 'globalThis.myValue');

  // ─── Signals ───────────────────────────────────────────
  final _engineStatus = signal('Initializing...');

  // 各个区块的运行结果
  final _basicResult = signal<String?>(null);
  final _typeResult = signal<String?>(null);
  final _callbackResult = signal<String?>(null);
  final _moduleResult = signal<String?>(null);
  final _promiseResult = signal<String?>(null);
  final _syntaxErrorResult = signal<String?>(null);
  final _runtimeErrorResult = signal<String?>(null);
  final _scriptResult = signal<String?>(null);
  final _globalResult = signal<String?>(null);

  // 全局面板运行锁
  final _isRunning = signal(false);

  // 额外的文本控制器（非代码编辑用途）
  final _callNameController = TextEditingController(text: 'greet');
  final _callArgsController = TextEditingController(text: '"World"');
  final _setGlobalNameController = TextEditingController(text: 'myValue');
  final _setGlobalValController = TextEditingController(text: '"Hello JSF!"');

  // ─── Lifecycle ──────────────────────────────────────────
  @override
  void initState() {
    // Platform.operatingSystem ==''
    super.initState();
    _initRuntime();
  }

  @override
  void dispose() {
    _js.dispose();
    _basicController.dispose();
    _typeController.dispose();
    _callbackController.dispose();
    _moduleController.dispose();
    _promiseController.dispose();
    _syntaxErrorController.dispose();
    _runtimeErrorController.dispose();
    _scriptController.dispose();
    _globalController.dispose();
    _callNameController.dispose();
    _callArgsController.dispose();
    _setGlobalNameController.dispose();
    _setGlobalValController.dispose();
    super.dispose();
  }

  /// 初始化 JS 运行时，注册 ES 模块和 Dart 回调。
  void _initRuntime() {
    try {
      // 注册 ES 模块
      _js.registerModules({
        'math': '''
export function add(a, b) { return a + b; }
export function multiply(a, b) { return a * b; }
export const PI = 3.14159;
''',
      });

      // 注册 Dart 回调：dartSum — JS 调用 Dart 求和
      _js.registerFunction('dartSum', (List<Object?> args) {
        return args.fold<num>(0, (sum, e) => sum + (e as num));
      });

      // 注册 Dart 回调：showMessage — 显示 Toast
      _js.registerFunction('showMessage', (List<Object?> args) {
        if (context.mounted) {
          showHosToast(context: context, message: args.first.toString());
        }
        return null;
      });
      _engineStatus.value = '✓ JSF (QuickJS)';
    } catch (e) {
      // _js = null;
      _engineStatus.value = '✗ Init failed: $e';
    }
  }

  // ─── 格式化 ──────────────────────────────────────────────

  /// 将 JSF eval 返回值格式化为可读字符串。
  String fmtDynamic(Object? value) {
    if (value == null) return 'null';
    if (value is JsUndefined) return 'undefined';
    if (value is JsArrayHole) return '<hole>';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return '[${value.map(fmtDynamic).join(', ')}]';
    }
    if (value is Map) {
      return '{${value.entries.map((e) => '${e.key}: ${fmtDynamic(e.value)}').join(', ')}}';
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is JsRegExp) return '/${value.source}/${value.flags}';
    if (value is JsErrorDetails) return 'Error: ${value.message}';
    if (value is JsTypedArray) {
      return '<${value.name}: ${value.values.length} elements>';
    }
    return value.toString();
  }

  // ─── JS 代码执行 ──────────────────────────────────────

  /// 执行 JS eval，结果写入 [resultSignal]，错误写入 [errorSignal]。
  Future<void> _execute({
    required String code,
    required Signal<String?> resultSignal,
    Signal<String?>? errorSignal,
    bool module = false,
  }) async {
    if (code.trim().isEmpty) {
      resultSignal.value = null;
      errorSignal?.value = null;
      return;
    }

    final runtime = _js;

    _isRunning.value = true;
    resultSignal.value = null;
    errorSignal?.value = null;

    try {
      final output = runtime.eval(code, module: module);
      resultSignal.value = fmtDynamic(output);
    } on JsException catch (e) {
      final msg = '${e.runtimeType}: ${e.message}';
      if (errorSignal != null) {
        errorSignal.value = msg;
      } else {
        resultSignal.value = '⚠ Error: $msg';
      }
    } catch (e) {
      final msg = e.toString();
      if (errorSignal != null) {
        errorSignal.value = msg;
      } else {
        resultSignal.value = '⚠ Error: $msg';
      }
    } finally {
      _isRunning.value = false;
    }
  }

  /// 执行 JS evalAsync（返回 Future）。
  Future<void> _executeAsync({
    required String code,
    required Signal<String?> resultSignal,
  }) async {
    if (code.trim().isEmpty) {
      resultSignal.value = null;
      return;
    }

    final runtime = _js;

    _isRunning.value = true;
    resultSignal.value = null;

    try {
      final output = await runtime.evalAsync(code);
      resultSignal.value = fmtDynamic(output);
    } on JsException catch (e) {
      resultSignal.value = '⚠ ${e.runtimeType}: ${e.message}';
    } catch (e) {
      resultSignal.value = '⚠ Error: $e';
    } finally {
      _isRunning.value = false;
    }
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final theme = HarmonyTheme.of(context);

      return HosPage(
        leading: const BackIcon(),
        title: 'JSF Demo',
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ═══ Engine Status ════════════════════════════
            _buildStatusBar(theme),
            const SizedBox(height: 16),

            // ═══ 1. Basic Evaluation ═════════════════════
            _buildSection(
              theme: theme,
              title: '1. 基础求值',
              subtitle: 'eval() 直接返回 Dart 类型（int/double/String/List/Map）',
              controller: _basicController,
              result: _basicResult,
              onRun: () => _execute(
                code: _basicController.text,
                resultSignal: _basicResult,
              ),
            ),
            const SizedBox(height: 12),

            // ═══ 2. Type Conversion ══════════════════════
            _buildSection(
              theme: theme,
              title: '2. 值与句柄',
              subtitle: 'evalValue() 保留 JS 对象身份，通过 getPropertyValue() 访问属性',
              controller: _typeController,
              result: _typeResult,
              onRun: () {
                final code = _typeController.text;
                final runtime = _js;
                if (code.trim().isEmpty) return;
                _isRunning.value = true;
                _typeResult.value = null;
                try {
                  // 使用 evalValue 获取 JsValue 句柄演示
                  final obj = runtime.evalValue(code);
                  final count = obj.getPropertyValue('count');
                  final name = obj.getPropertyValue('name');
                  final items = obj.getPropertyValue('items');
                  final result =
                      '{count: ${count.toDart()}, name: ${name.toDart()}, items: ${items.toDart()}}';
                  // 手动释放句柄
                  items.dispose();
                  name.dispose();
                  count.dispose();
                  obj.dispose();
                  _typeResult.value = result;
                } on JsException catch (e) {
                  _typeResult.value = '⚠ $e';
                } finally {
                  _isRunning.value = false;
                }
              },
            ),
            const SizedBox(height: 12),

            // ═══ 3. Dart Callback ════════════════════════
            _buildSection(
              theme: theme,
              title: '3. Dart 回调',
              subtitle: 'registerFunction() 将 Dart 函数注册到 JS 全局，JS 调用并获取返回值',
              controller: _callbackController,
              result: _callbackResult,
              onRun: () => _execute(
                code: _callbackController.text,
                resultSignal: _callbackResult,
              ),
            ),
            const SizedBox(height: 12),

            // ═══ 4. ES Modules ═══════════════════════════
            _buildSection(
              theme: theme,
              title: '4. ES 模块',
              subtitle: 'registerModules() 注册内存模块，JS 端 import 使用',
              controller: _moduleController,
              result: _moduleResult,
              onRun: () => _execute(
                code: _moduleController.text,
                resultSignal: _moduleResult,
              ),
            ),
            const SizedBox(height: 12),

            // ═══ 5. Promise / Async ══════════════════════
            _buildSection(
              theme: theme,
              title: '5. Promise / Async',
              subtitle: 'evalAsync() 自动 await Promise，返回 Future<dynamic>',
              controller: _promiseController,
              result: _promiseResult,
              onRun: () => _executeAsync(
                code: _promiseController.text,
                resultSignal: _promiseResult,
              ),
            ),
            const SizedBox(height: 12),

            // ═══ 6. Error Handling ═══════════════════════
            _buildErrorSection(theme),
            const SizedBox(height: 12),

            // ═══ 7. InitScript + Call ════════════════════
            _buildScriptCallSection(theme),
            const SizedBox(height: 12),

            // ═══ 8. Global Variables ═════════════════════
            _buildGlobalSection(theme),
            const SizedBox(height: 64),
          ],
        ),
      );
    });
  }

  // ─── Build Helpers ───────────────────────────────────────

  /// 引擎状态栏。
  Widget _buildStatusBar(HarmonyThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(_engineStatus.value, style: theme.typography.caption),
        ),
      ],
    );
  }

  /// 构建一个标准 Demo 区块。
  Widget _buildSection({
    required HarmonyThemeData theme,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required Signal<String?> result,
    required VoidCallback onRun,
  }) {
    final resultText = result.value;
    return HosCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.title3?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.typography.caption?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          HosTextInput(
            controller: controller,
            placeholder: '输入 JavaScript 代码',
            maxLines: 4,
            minLines: 2,
          ),
          const SizedBox(height: 12),
          HosButton(
            onPressed: _isRunning.value ? null : onRun,
            child: _isRunning.value
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
          if (resultText != null && resultText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildResultBox(theme: theme, text: resultText, isError: false),
          ],
        ],
      ),
    );
  }

  /// 错误处理区块。
  Widget _buildErrorSection(HarmonyThemeData theme) {
    final syntaxError = _syntaxErrorResult.value;
    final runtimeError = _runtimeErrorResult.value;

    return HosCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6. 错误处理',
            style: theme.typography.title3?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JS 异常转为 JsException，包含 message 和类型信息',
            style: theme.typography.caption?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // ── 语法错误 ──
          Text(
            '语法错误',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          HosTextInput(
            controller: _syntaxErrorController,
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 8),
          _isRunning.value
              ? const SizedBox()
              : HosTextButton(
                  onPressed: () => _execute(
                    code: _syntaxErrorController.text,
                    resultSignal: _syntaxErrorResult,
                  ),
                  child: const Text('引发语法错误'),
                ),
          if (syntaxError != null) ...[
            const SizedBox(height: 8),
            _buildResultBox(theme: theme, text: syntaxError, isError: true),
          ],
          const SizedBox(height: 16),

          // ── 运行时错误 ──
          Text(
            '运行时错误',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          HosTextInput(
            controller: _runtimeErrorController,
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 8),
          _isRunning.value
              ? const SizedBox()
              : HosTextButton(
                  onPressed: () => _execute(
                    code: _runtimeErrorController.text,
                    resultSignal: _runtimeErrorResult,
                  ),
                  child: const Text('引发运行时错误'),
                ),
          if (runtimeError != null) ...[
            const SizedBox(height: 8),
            _buildResultBox(theme: theme, text: runtimeError, isError: true),
          ],
        ],
      ),
    );
  }

  /// 初始化脚本 + Call 区块。
  ///
  /// 用 execInitScript() 预加载函数定义，
  /// 然后通过 call() 调用已注册的函数。
  Widget _buildScriptCallSection(HarmonyThemeData theme) {
    final resultText = _scriptResult.value;
    return HosCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7. 初始化脚本 + Call',
            style: theme.typography.title3?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'execInitScript() 预加载函数，然后 call() 按名调用',
            style: theme.typography.caption?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // 脚本输入
          Text(
            'JS 函数定义',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          HosTextInput(controller: _scriptController, maxLines: 3, minLines: 2),
          const SizedBox(height: 12),

          // 调用参数
          Text(
            '调用函数',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: HosTextInput(
                  controller: _callNameController,
                  placeholder: '函数名',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: HosTextInput(
                  controller: _callArgsController,
                  placeholder: '参数（逗号分隔）',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              HosButton(
                onPressed: _isRunning.value
                    ? null
                    : () {
                        final runtime = _js;
                        _isRunning.value = true;
                        _scriptResult.value = null;
                        try {
                          runtime.execInitScript(_scriptController.text);
                          _scriptResult.value = '✓ 脚本已加载';
                        } catch (e) {
                          _scriptResult.value = '⚠ 加载失败: $e';
                        } finally {
                          _isRunning.value = false;
                        }
                      },
                child: const Text('加载脚本'),
              ),
              const SizedBox(width: 12),
              HosOutlinedButton(
                onPressed: _isRunning.value
                    ? null
                    : () {
                        final runtime = _js;
                        _isRunning.value = true;
                        _scriptResult.value = null;
                        try {
                          // 解析参数（简易逗号分隔，每个尝试转 JSON）
                          final rawArgs = _callArgsController.text;
                          final args = rawArgs.isEmpty
                              ? <Object?>[]
                              : rawArgs.split(',').map((s) {
                                  final trimmed = s.trim();
                                  if (trimmed == 'true') return true;
                                  if (trimmed == 'false') return false;
                                  if (trimmed == 'null') return null;
                                  if (trimmed.startsWith('"') &&
                                      trimmed.endsWith('"')) {
                                    return trimmed.substring(
                                      1,
                                      trimmed.length - 1,
                                    );
                                  }
                                  if (trimmed.startsWith("'") &&
                                      trimmed.endsWith("'")) {
                                    return trimmed.substring(
                                      1,
                                      trimmed.length - 1,
                                    );
                                  }
                                  // 尝试数字
                                  final n = num.tryParse(trimmed);
                                  if (n != null) return n;
                                  return trimmed;
                                }).toList();
                          final result = runtime.call(
                            _callNameController.text,
                            args,
                          );
                          _scriptResult.value = '结果: ${fmtDynamic(result)}';
                        } catch (e) {
                          _scriptResult.value = '⚠ 调用失败: $e';
                        } finally {
                          _isRunning.value = false;
                        }
                      },
                child: const Text('调用函数'),
              ),
            ],
          ),

          if (resultText != null && resultText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildResultBox(theme: theme, text: resultText, isError: false),
          ],
        ],
      ),
    );
  }

  /// 全局变量区块 —— setGlobal() + getGlobalValue() 演示。
  Widget _buildGlobalSection(HarmonyThemeData theme) {
    final resultText = _globalResult.value;
    return HosCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8. 全局变量',
            style: theme.typography.title3?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'setGlobal() 从 Dart 设置 JS 全局变量，getGlobalValue() 读取',
            style: theme.typography.caption?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // 设置全局变量
          Text(
            '设置全局变量',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: HosTextInput(
                  controller: _setGlobalNameController,
                  placeholder: '变量名',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: HosTextInput(
                  controller: _setGlobalValController,
                  placeholder: '值',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HosButton(
            onPressed: _isRunning.value
                ? null
                : () {
                    final runtime = _js;
                    _isRunning.value = true;
                    _globalResult.value = null;
                    try {
                      final name = _setGlobalNameController.text.trim();
                      final val = _setGlobalValController.text.trim();
                      if (name.isEmpty) {
                        _globalResult.value = '⚠ 变量名不能为空';
                        return;
                      }
                      // 尝试作为 JS 表达式 eval，失败则作为原始字符串
                      Object? parsed;
                      try {
                        parsed = runtime.eval(val);
                      } catch (_) {
                        parsed = val;
                      }
                      runtime.setGlobal(name, parsed);
                      _globalResult.value =
                          '✓ globalThis.$name = ${fmtDynamic(parsed)}';
                    } catch (e) {
                      _globalResult.value = '⚠ 设置失败: $e';
                    } finally {
                      _isRunning.value = false;
                    }
                  },
            child: const Text('设置全局变量'),
          ),
          const SizedBox(height: 16),

          // 读取全局变量
          Text(
            '读取全局变量',
            style: theme.typography.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          HosTextInput(controller: _globalController, maxLines: 2, minLines: 1),
          const SizedBox(height: 8),
          HosButton(
            onPressed: _isRunning.value
                ? null
                : () {
                    _execute(
                      code: _globalController.text,
                      resultSignal: _globalResult,
                    );
                  },
            child: const Text('读取'),
          ),

          if (resultText != null && resultText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildResultBox(theme: theme, text: resultText, isError: false),
          ],
        ],
      ),
    );
  }

  /// 结果展示框。
  Widget _buildResultBox({
    required HarmonyThemeData theme,
    required String text,
    required bool isError,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? HarmonyColors.errorColor.withValues(alpha: 0.1)
            : theme.colorTokens.surfaceBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: theme.typography.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: isError ? HarmonyColors.errorColor : theme.accentColor.normal,
        ),
      ),
    );
  }
}

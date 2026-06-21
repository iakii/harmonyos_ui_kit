import 'dart:async';
import 'dart:convert';

import '../../js_runtime.dart';

/// JS↔Dart **真正同步**回调处理器。
///
/// 通过独立的 sync_bridge（全局 Mutex + Condvar）实现：
/// 1. JS 调用注册的同步函数 → worker 线程**阻塞等待**
/// 2. Dart 主线程通过 Timer 实时轮询 → 执行 handler
/// 3. Dart 返回结果 → worker 被唤醒 → JS 继续执行
///
/// ```dart
/// final handler = JsCallbackHandler(engine);
///
/// // 注册——JS 调用时立刻同步执行 Dart handler
/// handler.register('sum', (args) {
///   return JsValue.integer(args[0].asIntegerSync! + args[1].asIntegerSync!);
/// });
///
/// // JS 端直接拿到结果，无需 await！
/// final result = await handler.eval('sum(3, 4) + 10');
/// print(result.asIntegerSync);  // 17
///
/// // 实时进度通知
/// handler.register('postMessage', (args) {
///   print('实时进度: ${args[1].asStringSync}');
///   return JsValue.none();
/// });
/// ```
class JsCallbackHandler {
  final JsEngine _engine;
  final Map<String, JsValue Function(List<JsValue>)> _handlers = {};

  /// 轮询间隔（毫秒）
  static const int _pollIntervalMs = 1;

  JsCallbackHandler(this._engine);

  // ─── 公开 API ──────────────────────────────────────────

  /// 注册一个**同步**回调方法。
  ///
  /// JS 端调用 `name(args)` **立刻拿到返回值**（无 Promise，无需 `await`）。
  /// 内部使用 [JsEngine.registerSyncFunction]，通过 sync_bridge 实现
  /// 真正的同步调用（worker 线程阻塞等待 Dart 响应）。
  void register(String name, JsValue Function(List<JsValue>) handler) {
    _handlers[name] = handler;
    _engine.registerSyncFunction(name: name);
  }

  /// 注销已注册的回调方法。
  void unregister(String name) {
    _handlers.remove(name);
    _engine.evalRaw(code: 'delete globalThis["$name"]');
  }

  /// 执行 JS 代码并返回结果。
  ///
  /// 发起 eval 的同时启动后台轮询，JS 执行期间**实时**处理同步回调。
  /// - JS 中 `name(args)` → Dart handler 立刻执行并返回结果
  /// - 无需 `await`，无阻塞延迟
  ///
  /// [cancelSignal] 可选：当此 Future 完成时，调用 [JsEngine.cancelEval]
  /// 取消正在等待的 eval。适用于页面返回/组件 dispose 场景。
  /// 取消后 eval 会抛出 [JsError.cancelled]。
  Future<JsValue> eval(String code, {Future<void>? cancelSignal}) async {
    // 启动后台轮询定时器
    final timer = Timer.periodic(
      Duration(milliseconds: _pollIntervalMs),
      (_) => _processSyncCalls(),
    );

    // 注册取消监听（在 finally 中统一清理）
    StreamSubscription<void>? cancelSub;
    if (cancelSignal != null) {
      cancelSub = cancelSignal.asStream().listen((_) {
        _engine.cancelEval();
      });
    }

    try {
      // 执行 JS（eval 会阻塞 worker，但 Dart 主线程的 Timer 持续运行）
      return await _engine.eval(code: code);
    } finally {
      cancelSub?.cancel();
      timer.cancel();
      // 最后再处理一轮，确保所有回调都已响应
      _processSyncCalls();
    }
  }

  /// 获取已注册的方法名列表。
  List<String> get registeredMethods => _handlers.keys.toList();

  /// 检查是否已注册某个方法。
  bool isRegistered(String name) => _handlers.containsKey(name);

  /// 获取底层 [JsEngine] 实例。
  JsEngine get engine => _engine;

  // ─── 内部方法 ──────────────────────────────────────────

  /// 轮询并处理所有待处理的同步调用（Worker→Dart）。
  void _processSyncCalls() {
    final calls = _engine.pollSyncCalls();
    for (final call in calls) {
      final handler = _handlers[call.name];
      if (handler != null) {
        try {
          final argsList = jsonDecode(call.argsJson) as List<dynamic>;
          final jsArgs = argsList.map((a) => _jsonToJsValue(a)).toList();
          final response = handler(jsArgs);
          final resultJson = jsonEncode(_jsValueToJson(response));
          _engine.resolveSyncCall(callId: call.callId, resultJson: resultJson);
        } catch (e) {
          _engine.rejectSyncCall(callId: call.callId, error: e.toString());
        }
      } else {
        _engine.rejectSyncCall(
          callId: call.callId,
          error: 'Unknown method: ${call.name}',
        );
      }
    }
  }

  // ─── JSON ↔ JsValue 转换（与 Rust 侧 frb_value_to_json 对应）──

  JsValue _jsonToJsValue(dynamic json) {
    if (json == null) return const JsValue.none();
    if (json is bool) return JsValue.boolean(json);
    if (json is int) return JsValue.integer(json);
    if (json is double) return JsValue.float(json);
    if (json is String) return JsValue.string(json);
    if (json is List) {
      return JsValue.array(json.map((e) => _jsonToJsValue(e)).toList());
    }
    if (json is Map<String, dynamic>) {
      return JsValue.object(
        json.entries.map((e) => (e.key, _jsonToJsValue(e.value))).toList(),
      );
    }
    return const JsValue.none();
  }

  dynamic _jsValueToJson(JsValue v) {
    return v.map(
      none: (_) => null,
      boolean: (v) => v.field0,
      integer: (v) => v.field0,
      float: (v) => v.field0,
      bigInt: (v) => v.field0,
      string: (v) => v.field0,
      bytes: (v) => v.field0,
      array: (v) => v.field0.map(_jsValueToJson).toList(),
      object: (v) => {for (final (k, val) in v.field0) k: _jsValueToJson(val)},
      date: (v) => v.field0,
      symbol: (v) => v.field0,
    );
  }
}

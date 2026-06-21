import '../../js_runtime.dart';

/// JS→Dart 回调处理器（Promise 模式）。
///
/// 通过 FRB 的 `registerGlobalFunction` + poll/resolve 机制实现 JS→Dart 调用。
/// JS 端使用 `await methodName(args)` 调用，返回 Promise。
///
/// **注意**：由于 JS 执行在独立工作线程中进行，不再支持真正的同步 FFI 回调。
/// JS 代码需使用 `await` 调用注册的方法。
///
/// ```dart
/// final handler = JsCallbackHandler(engine);
///
/// // 注册回调——JS 调用时通过 Promise 返回结果
/// handler.register('sum', (args) {
///   return JsValue.integer(args[0].asIntegerSync + args[1].asIntegerSync);
/// });
///
/// // JS 端使用 await 获取结果
/// final result = await handler.eval('await sum(3, 4)');
/// print(result.asIntegerSync);  // 7
/// ```
class JsCallbackHandler {
  final JsEngine _engine;
  final Map<String, JsValue Function(List<JsValue>)> _handlers = {};

  JsCallbackHandler(this._engine);

  // ─── 公开 API ──────────────────────────────────────────

  /// 注册一个回调方法。
  ///
  /// JS 端通过 `await name(args)` 调用（返回 Promise），
  /// Dart handler 的返回值会 resolve 该 Promise。
  ///
  /// 内部使用 [JsEngine.registerGlobalFunction]（Promise 模式）。
  void register(String name, JsValue Function(List<JsValue>) handler) {
    _handlers[name] = handler;
    _engine.registerGlobalFunction(name: name);
  }

  /// 注销已注册的回调方法。
  void unregister(String name) {
    _handlers.remove(name);
    _engine.evalRaw(code: 'delete globalThis["$name"]');
  }

  /// 执行 JS 代码并返回结果。
  ///
  /// 使用 [JsEngine.eval] 执行代码，自动处理 Promise 解析和回调轮询。
  /// 如果 JS 代码中调用了注册的回调，会自动 poll/resolve。
  Future<JsValue> eval(String code) async {
    final result = await _engine.eval(code: code);
    await _processPendingCallbacks();
    return result;
  }

  /// 获取已注册的方法名列表。
  List<String> get registeredMethods => _handlers.keys.toList();

  /// 检查是否已注册某个方法。
  bool isRegistered(String name) => _handlers.containsKey(name);

  /// 获取底层 [JsEngine] 实例。
  JsEngine get engine => _engine;

  // ─── 内部方法 ──────────────────────────────────────────

  /// 轮询并处理所有待处理的 JS→Dart 回调。
  Future<void> _processPendingCallbacks() async {
    // 循环处理直到没有更多待处理调用
    bool hadCalls = true;
    while (hadCalls) {
      hadCalls = false;
      final calls = _engine.pollCalls();
      for (final call in calls) {
        hadCalls = true;
        final handler = _handlers[call.name];
        if (handler != null) {
          try {
            final response = handler(call.params);
            _engine.resolveCall(callId: call.callId, result: response);
          } catch (e) {
            _engine.rejectCall(callId: call.callId, error: e.toString());
          }
        } else {
          _engine.rejectCall(
            callId: call.callId,
            error: 'Unknown method: ${call.name}',
          );
        }
      }
      // 运行微任务队列，触发 .then() 回调
      _engine.runJobs();
    }
  }
}

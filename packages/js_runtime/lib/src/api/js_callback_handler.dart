import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart' show malloc;

import '../../js_runtime.dart';

/// C 函数指针签名：`char* handler(const char* request_json)`
///
/// 请求 JSON: `{"n":"method","a":"[args_json]"}`
/// 响应 JSON: `{"v":result_json}` 或 `{"e":"error_message"}`
///
/// 返回的指针由 Rust 侧 `CString::from_raw` 接管释放。
typedef _HandleCallC = Pointer<Int8> Function(Pointer<Int8> requestJson);

/// JS→Dart 同步回调处理器。
///
/// 通过 `dart:ffi` 的 `NativeCallable.isolateLocal` 建立 Rust→Dart 的**同步调用通道**。
/// JS 调用注册方法时立刻同步执行 Dart handler 并返回结果（无 Promise）。
///
/// ```dart
/// final handler = JsCallbackHandler(engine);
///
/// // 注册——JS 调用时立刻响应
/// handler.register('sum', (args) {
///   return JsValue.integer(args[0].asIntegerSync + args[1].asIntegerSync);
/// });
///
/// // JS 端直接拿到结果，无需 await！
/// final result = handler.eval('sum(3, 4) + 10');
/// print(result.asIntegerSync);  // 17
/// ```
class JsCallbackHandler {
  final JsEngine _engine;
  final Map<String, JsValue Function(List<JsValue>)> _handlers = {};
  late final NativeCallable<_HandleCallC> _callable;

  JsCallbackHandler(this._engine) {
    // 创建同步 FFI 回调。所有注册的方法共享这同一个 C 函数指针，
    // 通过 JSON 请求中的 "n" 字段（方法名）分发到对应 handler。
    _callable = NativeCallable<_HandleCallC>.isolateLocal(_handleCall);

    // 将函数指针传给 Rust 侧（PlatformInt64 = int）
    _engine.registerDartHandler(ptr: _callable.nativeFunction.address);
  }

  /// 所有 JS→Dart 同步调用的入口点。
  ///
  /// 从 Rust 侧通过 C FFI 直接调用（同线程，同步）。
  /// 返回的指针由 Rust 侧 `CString::from_raw` 接管释放。
  Pointer<Int8> _handleCall(Pointer<Int8> requestPtr) {
    try {
      final requestJson = _readCString(requestPtr);
      final request = jsonDecode(requestJson) as Map<String, dynamic>;
      final methodName = request['n'] as String;
      final argsJson = request['a'] as String;
      final argsList = jsonDecode(argsJson) as List<dynamic>;

      final handler = _handlers[methodName];
      if (handler == null) {
        return _allocCString(jsonEncode({'e': 'Unknown method: $methodName'}));
      }

      // 将 JSON args 转为 JsValue 列表
      final jsArgs = argsList.map((a) => _jsonToJsValue(a)).toList();

      // 执行 Dart handler
      final result = handler(jsArgs);

      // 将结果序列化为 JSON
      final resultJson = jsonEncode(_jsValueToJson(result));
      return _allocCString(jsonEncode({'v': resultJson}));
    } catch (e) {
      return _allocCString(jsonEncode({'e': e.toString()}));
    }
  }

  // ─── C 字符串工具 ─────────────────────────────────────

  /// 从 null-terminated C 字符串指针读取 Dart String。
  static String _readCString(Pointer<Int8> ptr) {
    final units = <int>[];
    var i = 0;
    while (ptr[i] != 0) {
      // Int8 是有符号的，高位为 1 的字节变成负数。
      // utf8.decode 期望无符号字节值 (0–255)，所以需要 & 0xFF。
      units.add(ptr[i] & 0xFF);
      i++;
    }
    return utf8.decode(units);
  }

  /// 分配 null-terminated C 字符串并返回指针。
  ///
  /// 调用者（Rust 侧）负责通过 `CString::from_raw` 释放内存。
  static Pointer<Int8> _allocCString(String str) {
    final bytes = utf8.encode(str);
    final ptr = malloc<Int8>(bytes.length + 1);
    for (var i = 0; i < bytes.length; i++) {
      ptr[i] = bytes[i];
    }
    ptr[bytes.length] = 0;
    return ptr;
  }

  // ─── JSON ↔ JsValue 转换 ──────────────────────────────

  /// 将 JSON 值转为 JsValue。
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

  /// 将 JsValue 转为 JSON 可序列化对象。
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
      object: (v) => {
        for (final (k, val) in v.field0) k: _jsValueToJson(val)
      },
      date: (v) => v.field0,
      symbol: (v) => v.field0,
    );
  }

  // ─── 公开 API ──────────────────────────────────────────

  /// 注册一个同步回调方法。
  ///
  /// JS 端调用 `name(args)` **直接返回结果**（无 Promise，无需 `await`）。
  ///
  /// 内部通过 FFI 同步调用 Dart handler。
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
  /// 注册的同步方法在 JS 执行期间**立刻响应**，不需要 poll loop。
  JsValue eval(String code) {
    return _engine.eval(code: code);
  }

  /// 获取已注册的方法名列表。
  List<String> get registeredMethods => _handlers.keys.toList();

  /// 检查是否已注册某个方法。
  bool isRegistered(String name) => _handlers.containsKey(name);

  /// 获取底层 [JsEngine] 实例。
  JsEngine get engine => _engine;
}

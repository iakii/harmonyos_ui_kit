# 计划：同步 FFI 回调 — JS 调用 Dart 方法立刻响应

## 问题

当前 Promise + 队列模式有根本缺陷：JS 调用注册方法后返回 Promise，必须等 JS 执行结束、Dart 处理队列、再 `runJobs()` 才能 resolve。和 Boa 模块函数的行为不一致——模块函数在 JS 调用时就**立刻同步执行**并返回结果。

## 根因

FRB 不支持同步的 Rust→Dart 回调（只有 `DartFnFuture`，异步）。但 `dart:ffi` 的 `NativeCallable.isolateLocal` **可以**创建同步的 C 函数指针，从 Rust 直接调用 Dart 闭包并立即拿到返回值。

## 方案

绕过 FRB 的回调限制，直接用 `dart:ffi` 建立一条 **Rust→Dart 的同步调用通道**：

```
JS 调用 sum(3, 4)
  → Boa 执行 NativeFunction
    → Rust 序列化 args 为 JSON
    → 通过函数指针调用 Dart 闭包（同步，同线程）
      → Dart 解析 JSON args
      → Dart 执行 handler
      → Dart 返回 JSON result
    → Rust 解析 JSON result → JsValue
  → 返回结果给 JS（无 Promise！）
JS 继续执行（无 await！）
```

## 改动

### 1. Rust: `JsValue` 添加 serde 序列化

**文件**: `rust/src/api/js_value.rs`

为 `JsValue` 添加 `#[derive(Serialize, Deserialize)]`（已有 serde 依赖），用于 FFI 层的 JSON 数据交换。

### 2. Rust: 新增同步回调基础设施

**文件**: `rust/src/js_runtime/internal.rs`

新增：
```rust
// Dart 回调函数指针类型
type DartCallHandler = unsafe extern "C" fn(*const c_char) -> *mut c_char;

thread_local! {
    static DART_HANDLERS: RefCell<HashMap<u64, DartCallHandler>> = ...;
}

pub(crate) fn register_dart_handler(runtime_id: u64, ptr: i64) { ... }
pub(crate) fn call_dart_handler(runtime_id: u64, method: &str, args_json: &str) -> Result<String, String> { ... }
pub(crate) fn create_sync_native_fn(method_name: String, runtime_id: u64) -> NativeFunction { ... }
```

`create_sync_native_fn` 创建的 NativeFunction **不创建 Promise**，而是：
1. 序列化 JS args → JSON
2. `call_dart_handler()` 同步调用 Dart 闭包
3. 反序列化 JSON → JsValue 返回给 JS

### 3. Rust: `JsEngine` 新增 API

**文件**: `rust/src/api/engine.rs`

```rust
/// （内部使用）注册 Dart FFI 回调函数指针。
#[frb(sync)]
pub fn register_dart_handler(&self, ptr: i64) -> Result<(), JsError>

/// 注册同步全局函数。JS 调用时立刻同步执行，不返回 Promise。
#[frb(sync)]
pub fn register_sync_function(&self, name: String) -> Result<(), JsError>
```

`register_sync_function` 内部调用 `create_sync_native_fn` + `register_global_callable`（用 FunctionObjectBuilder 设置 constructor=false）。

### 4. Dart: `JsCallbackHandler` 重写

**文件**: `lib/src/api/js_callback_handler.dart`

```dart
import 'dart:ffi';
import 'dart:convert';

typedef HandleCallC = Pointer<Int8> Function(Pointer<Int8>);

class JsCallbackHandler {
  final JsEngine _engine;
  final Map<String, JsValue Function(List<JsValue>)> _handlers = {};
  late final NativeCallable<HandleCallC> _callable;

  JsCallbackHandler(this._engine) {
    // 创建同步 FFI 回调，所有 handler 共享这一个函数指针
    _callable = NativeCallable<HandleCallC>.isolateLocal(_handleCall);
    _engine.registerDartHandler(ptr: BigInt.from(_callable.nativeFunction.address));
  }

  // 所有 JS→Dart 调用的入口（C 函数指针）
  Pointer<Int8> _handleCall(Pointer<Int8> requestPtr) { ... }

  /// 注册同步回调（立刻响应，无 Promise）
  void register(String name, JsValue Function(List<JsValue>) handler) {
    _handlers[name] = handler;
    _engine.registerSyncFunction(name: name);
  }

  /// 执行 JS（直接用 eval，无需 poll loop）
  JsValue eval(String code) => _engine.eval(code: code);
}
```

`_handleCall` 的 JSON 协议：
- **请求**: `{"n":"sum", "a":"[3,4]"}` — n=方法名, a=args JSON
- **成功响应**: `{"v":7}` — v=JsValue JSON
- **错误响应**: `{"e":"error message"}`

### 5. FRB codegen

修改 Rust API 后运行 `flutter_rust_bridge_codegen generate` 同步 Dart 端。

## 效果对比

| | 之前（Promise 模式） | 之后（同步 FFI） |
|---|---|---|
| JS 调用方式 | `await sum(3,4)` | `sum(3,4)` 直接拿到值 |
| 响应时机 | eval 结束后 drain 才处理 | **JS 调用时立刻执行** |
| eval 写法 | `evalRaw` + poll loop | `eval()` 直接可用 |
| 和模块函数一致 | ❌ | ✅ |

## 改动文件清单

| 操作 | 文件 |
|------|------|
| 修改 | `rust/src/api/js_value.rs` — 加 serde derive |
| 修改 | `rust/src/api/engine.rs` — 加 `register_dart_handler`、`register_sync_function` |
| 修改 | `rust/src/js_runtime/internal.rs` — 加 DART_HANDLERS、同步回调函数 |
| 修改 | `lib/src/api/js_callback_handler.dart` — 加 FFI NativeCallable，重写 register/eval |
| 自动生成 | `rust/src/frb_generated.rs`、`lib/src/frb/**` |

## 验证

```bash
flutter pub get
flutter analyze
cargo build
```

功能验证：
```dart
final handler = JsCallbackHandler(engine);
handler.register('sum', (args) {
  return JsValue.integer(args[0].asIntegerSync + args[1].asIntegerSync);
});

// 无 await，直接拿到结果
final result = handler.eval('sum(3, 4) + 10');
print(result.asIntegerSync);  // 17
```

## 0.0.1

* TODO: Describe initial release.

## 同步 FFI 回调 (2026-06-20)

### 新增
- `JsCallbackHandler` — 基于 `dart:ffi` `NativeCallable.isolateLocal` 的同步回调处理器，JS 调用立刻响应（无 Promise）
- `JsEngine.registerDartHandler(ptr)` — 注册 Dart FFI 回调函数指针
- `JsEngine.registerSyncFunction(name)` — 注册同步全局函数（内部使用 `create_sync_native_fn`）
- Rust↔Dart 同步 FFI 通道：`DART_HANDLERS`、`create_sync_native_fn`、`call_dart_handler`

### 修复
- `_readCString`: `Pointer<Int8>` 有符号字节值加 `& 0xFF` 转无符号（修复中文/特殊字符 UTF-8 报错）
- JSON 协议统一：改为 `serde_json::Value` 原始格式（修复 Dart↔Rust 序列化不匹配）

### 说明
- `JsCallbackHandler.register()` 使用 `registerSyncFunction`（FFI 同步回调），JS 侧 `name(args)` 直接返回结果
- Promise 模式（`registerGlobalCallable` / `registerGlobalFunction`）保留作为高级选项

---

## 重构: JS↔Dart 交互 API (2026-06-20)

### 新增
- `JsEngine.register_global_callable(name)` — 使用 Boa `context.register_global_callable()` 注册可构造+可调用的全局 JS 函数
- `JsEngine.register_global_function(name)` — 使用 `FunctionObjectBuilder` 注册不可构造的纯函数
- `JsEngine.poll_calls()` — 统一拉取所有待处理回调请求，返回 `List<CompletedCall>`
- `JsEngine.reject_call(call_id, error)` — 回传错误 reject JS Promise
- `CompletedCall` 类型 — JS→Dart 方法调用的统一请求类型（`callId` / `name` / `params`）

### 删除
- `JsEngine.post_message` / `poll_messages` / `has_messages` — 旧消息通道
- `JsEngine.register_method` / `unregister_method` / `poll_method_calls` / `resolve_call` — 旧回调系统
- `JsMessage` 类型 (Rust + Dart)
- `MethodCall` 类型 (Rust + Dart)
- `JsMethodBridge` Dart 便捷类
- `__postMessage` JS 全局函数

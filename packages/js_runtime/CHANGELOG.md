## 0.0.1

* TODO: Describe initial release.

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

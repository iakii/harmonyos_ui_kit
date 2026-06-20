# Dart↔JS 回调注册通道

## Context

用户需要将双向通信改为**注册回调模式**：Dart 注册一个方法（如 `sum`），JS 直接调用 `sum(3, 4)`，内部同步执行 Dart 代码并返回结果。

当前已有的 `postMessage`/`pollMessages` 消息队列模式保留作为辅助通道，新增 `registerMethod`/`unregisterMethod` 作为主要回调机制。

## 核心设计：u64 句柄 + thread_local 回调表

为什么用句柄而不是直接捕获回调？
- Boa 的 `NativeFunction::from_copy_closure` 要求闭包捕获类型为 `Copy`
- `from_copy_closure_with_captures` 要求 captures 实现 `boa_gc::Trace`（仅基础 Rust 类型支持）
- FRB 的 Dart 回调包装器不是 `Copy` 也不是 `Trace`

方案：NativeFunction 闭包只捕获 `u64` 句柄（Copy），真实回调存在独立 thread_local 表中：

```
Dart 调用 registerMethod("sum", callback)
    │
    ▼
Rust: Box::new(callback) → METHOD_CALLBACKS[handle]
    创建 NativeFunction::from_copy_closure(handle)
    注册到 global 对象: globalThis.sum
    │
    ▼
JS 调用 sum(3, 4)
    │
    ▼
NativeFunction 闭包执行:
  - 从 METHOD_CALLBACKS[handle] 取出 callback
  - Boa args → Vec<JsValue> (from_boa)
  - callback(params) → 同步执行 Dart 代码
  - JsValue → Boa JsValue (to_boa)
  - 返回给 JS
```

## 修改文件清单

### 1. 修改 `rust/src/js_runtime/internal.rs`

新增 thread_local 回调和句柄分配器：

```rust
use std::collections::HashMap;

thread_local! {
    pub(crate) static METHOD_CALLBACKS: RefCell<HashMap<u64, MethodCallbackEntry>> =
        RefCell::new(HashMap::new());
}

pub(crate) struct MethodCallbackEntry {
    pub callback: Box<dyn Fn(Vec<FrbJsValue>) -> FrbJsValue + 'static>,
    pub runtime_id: u64,
}

pub(crate) fn next_callback_handle() -> u64 {
    use std::sync::atomic::AtomicU64;
    static NEXT: AtomicU64 = AtomicU64::new(0);
    NEXT.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}
```

### 2. 修改 `rust/src/api/engine.rs`

在 JsEngine impl 块新增：

**`register_method`** (`#[frb(sync)]`):
```rust
pub fn register_method(
    &self,
    name: String,
    callback: impl Fn(Vec<JsValue>) -> JsValue + 'static,
) -> Result<(), JsError>
```
- 分配 handle
- Box 并存入 METHOD_CALLBACKS
- 创建 `NativeFunction::from_copy_closure`（捕获 handle: u64）
- 闭包内：转换 args → 查回调 → 调用 → 转换结果 → 异常捕获
- 在 global 对象注册为 `name`

**`unregister_method`** (`#[frb(sync)]`):
```rust
pub fn unregister_method(&self, name: String) -> Result<(), JsError>
```
- 从 global 对象删除属性
- 从 METHOD_CALLBACKS 删除对应 entry

**修改 `close()`**：遍历 METHOD_CALLBACKS 清理关联 runtime_id 的回调。

### 3. 修改 `rust/src/api/mod.rs`

无需新增文件（复用 `js_message.rs` 中的类型）。

### 4. FRB 代码生成 + Dart 导出

运行 `flutter_rust_bridge_codegen generate`，生成的 Dart API：
```dart
// JsEngine 新增方法
void registerMethod({
  required String name,
  required JsValue Function(List<JsValue>) callback,
});

void unregisterMethod({required String name});
```

### 5. 保留现有消息通道

`postMessage`/`pollMessages`/`hasMessages` 保持不变，作为 fire-and-forget 单向（JS→Dart）通道。

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| FRB v2.13 不支持 `impl Fn` 参数 | 回退方案：用 Dart 传入 String（函数名），Rust 不持有回调，回调通过 eval 间接执行 |
| Dart 回调抛出异常 | Boa NativeFunction 内用 `catch_unwind` 捕获 panic，转为 JS 异常 |
| `to_boa()` 需要 `&mut Context` 但闭包签名是 `&mut Context<'_>` | 已验证兼容：闭包接收 `&mut Context`，可直接传给 `to_boa` |
| 已注册方法的内存泄漏 | `close()` 时清理 METHOD_CALLBACKS 中所有关联 runtime_id 的 entry |
| 同一 runtime 重复注册同名方法 | 后注册覆盖前注册（与 JS 语义一致），旧回调 entry 被替换并释放 |

## 验证

1. `cargo build` — Rust 编译通过
2. `flutter_rust_bridge_codegen generate` — 代码生成成功
3. `flutter pub get && flutter analyze` — Dart 分析通过
4. 端到端测试：
   - Dart 注册 `sum` 方法（接收两数，返回和）
   - `engine.eval('sum(3, 4)')` → 返回 `7`
   - Dart 注册 `greet`（接收 name，返回字符串）
   - JS 调用 `greet("World")` → 返回 `"Hello, World!"`

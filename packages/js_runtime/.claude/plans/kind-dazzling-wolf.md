# 用 FRB dart_callback 重写 JS↔Dart 回调，移除旧 API

## Context

当前项目用自定义 `sync_bridge`（Mutex+Condvar）+ `dart:ffi` NativeCallable + Promise 队列 三套机制实现 JS↔Dart 回调，复杂度高。flutter_rust_bridge v2 已提供原生 `dart_callback: impl Fn(String) -> DartFnFuture<String>`，可统一替代。

参考：
- FRB Rust→Dart 指南：https://cjycode.com/flutter_rust_bridge/guides/direction/rust-call-dart
- KossJS 注册模式：https://github.com/KossJS/KossJS/blob/main/src/runtime.rs

## 目标 API

```dart
final engine = JsEngine.create();

// 注册 Dart 回调 —— 简洁直接，无中间层
await engine.register('add', (args) => args[0] + args[1]);

// JS 直接调用，无 Promise
final result = await engine.eval(code: 'add(3, 4) + 10'); // 17
```

---

## 架构

```
JS 调用 add(3, 4)
  → Boa NativeFunction 闭包 (worker 线程, 同步上下文)
    → 序列化 args → JSON
    → dart_callbacks::call_blocking() → rt.block_on(dart_callback(args_json))
      → FRB 内部通道 → Dart handler → 返回 JSON
    → 反序列化 JSON → JsValue
  → 返回 7 给 JS
```

核心约束：Boa NativeFunction 闭包是同步的，`DartFnFuture` 是异步的。解决方案：worker 线程创建 tokio runtime，`block_on` 桥接。

---

## 实施计划

### Step 1: 添加 tokio 依赖 + Worker runtime

**改 `rust/Cargo.toml`:**
```toml
tokio = { version = "1", features = ["rt"] }
```

**改 `rust/src/js_runtime/internal.rs` — RuntimeState 加字段:**
```rust
pub(crate) struct RuntimeState {
    pub context: Context,
    pub max_memory: u64,
    pub estimated_memory: u64,
    pub total_code_bytes: u64,
    pub total_module_bytes: u64,
    pub runtime_id: u64,                                    // 新增
    pub runtime_handle: Option<tokio::runtime::Handle>,     // 新增
}
```

**改 `rust/src/js_runtime/worker.rs` — worker_loop:**
```rust
fn worker_loop(rx: mpsc::Receiver<WorkerCmd>, max_memory: u64, runtime_id: u64) {
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_time()
        .build()
        .expect("worker tokio runtime");

    let mut state = match internal::init_context(max_memory, runtime_id) {
        Ok(s) => s,
        Err(e) => { eprintln!("..."); return; }
    };
    state.runtime_handle = Some(rt.handle().clone());

    while let Ok(cmd) = rx.recv() { /* dispatch */ }
}
```

`init_context` 签名改为接收 `runtime_id`。

### Step 2: 新建 `dart_callbacks.rs` — 全局回调注册表

**新建 `rust/src/js_runtime/dart_callbacks.rs`:**

```rust
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use flutter_rust_bridge::DartFnFuture;

/// 类型擦除的 dart_callback
type DartCallback = Arc<dyn Fn(String) -> DartFnFuture<String> + Send + Sync + 'static>;

/// 全局注册表，按 (runtime_id, name) 索引，独立于 worker channel
static CALLBACKS: std::sync::LazyLock<Mutex<HashMap<(u64, String), DartCallback>>> =
    std::sync::LazyLock::new(|| Mutex::new(HashMap::new()));

pub(crate) fn register(runtime_id: u64, name: String, cb: DartCallback) {
    CALLBACKS.lock().expect("poisoned").insert((runtime_id, name), cb);
}

pub(crate) fn unregister(runtime_id: u64, name: &str) {
    CALLBACKS.lock().expect("poisoned").remove(&(runtime_id, name.to_string()));
}

pub(crate) fn unregister_all(runtime_id: u64) {
    CALLBACKS.lock().expect("poisoned").retain(|(rid, _), _| *rid != runtime_id);
}

/// Worker 线程调用：block_on 等待 Dart 响应
pub(crate) fn call_blocking(
    runtime_id: u64,
    name: &str,
    args_json: &str,
    rt: &tokio::runtime::Handle,
) -> Result<String, String> {
    let cb = {
        let map = CALLBACKS.lock().map_err(|e| format!("lock: {e}"))?;
        map.get(&(runtime_id, name.to_string()))
            .ok_or_else(|| format!("'{}' not registered", name))?
            .clone()
    };
    match rt.block_on(cb(args_json.to_string())) {
        Ok(v) => Ok(v),
        Err(e) => Err(format!("dart: {e}")),
    }
}
```

**改 `rust/src/js_runtime/mod.rs`:**
```rust
pub(crate) mod dart_callbacks;
pub(crate) mod internal;
pub(crate) mod sync_bridge;  // 待删除
pub(crate) mod worker;
```

### Step 3: 新建 `create_dart_callback_fn` — NativeFunction 工厂

**改 `rust/src/js_runtime/internal.rs`** — 新增函数，复用已有 `frb_value_to_json` / `json_to_frb_value`:

```rust
use boa_engine::JsNativeError;

pub(crate) fn create_dart_callback_fn(
    method_name: String,
    runtime_id: u64,
    runtime_handle: tokio::runtime::Handle,
) -> NativeFunction {
    NativeFunction::from_copy_closure_with_captures(
        move |_this, args, _name, ctx| -> boa_engine::JsResult<BoaJsValue> {
            // 1. JS args → JSON
            let vals: Vec<serde_json::Value> = args.iter()
                .map(|v| frb_value_to_json(&FrbJsValue::from_boa(v, ctx)))
                .collect();
            let args_json = serde_json::to_string(&vals).unwrap_or_default();

            // 2. 同步等待 Dart 响应
            let raw = crate::js_runtime::dart_callbacks::call_blocking(
                runtime_id, &method_name, &args_json, &runtime_handle,
            );

            // 3. JSON → JsValue
            match raw {
                Ok(json) => {
                    let v: serde_json::Value = serde_json::from_str(&json).unwrap_or_default();
                    json_to_frb_value(&v).to_boa(ctx).map_err(|e| {
                        JsNativeError::typ().with_message(format!("{e}")).into()
                    })
                }
                Err(e) => Err(JsNativeError::typ().with_message(e).into()),
            }
        },
        method_name,
    )
}
```

同时修改已有 `create_sync_native_fn` 中的错误构造（`from_native(...)` → `.into()`），为后续保留兼容。

### Step 4: Worker 侧 — 新增 Register 命令

**改 `rust/src/js_runtime/worker.rs`** — WorkerCmd 新增变体:
```rust
/// 注册 dart_callback 作为 JS 全局函数
Register {
    name: String,
    reply: mpsc::Sender<Result<(), JsError>>,
},
```

Worker loop 分发:
```rust
WorkerCmd::Register { name, reply } => {
    let result = register_inner(&mut state, &name);
    let _ = reply.send(result);
}
```

**注册函数（KossJS 三步模式）:**
```rust
fn register_inner(state: &mut RuntimeState, name: &str) -> Result<(), JsError> {
    use boa_engine::{js_string, property::Attribute};

    let rt_handle = state.runtime_handle.clone().ok_or_else(|| JsError::Internal {
        message: "runtime not available".into(),
    })?;

    let native_fn = internal::create_dart_callback_fn(
        name.to_string(), state.runtime_id, rt_handle,
    );

    let js_func = native_fn.to_js_function(state.context.realm());

    state.context.register_global_property(
        js_string!(name),
        js_func,
        Attribute::WRITABLE | Attribute::CONFIGURABLE,
    ).map_err(|e| JsError::Internal {
        message: format!("Failed to register '{name}': {e}"),
    })
}
```

**公共函数:**
```rust
pub(crate) fn register(runtime_id: u64, name: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::Register { name, reply: tx })
}
```

### Step 5: 仅 JsEngine 暴露 `register` — JsRuntime 不暴露

`register` 是高层 API，**只在 `JsEngine` 上暴露**。低层 `JsRuntime` 不提供此方法，保持其纯粹的 eval/模块/内存管理职责。

**改 `rust/src/api/engine.rs`:**

新增唯一的注册方法，替代旧的 `register_sync_function` / `register_global_callable` / `register_global_function`:

```rust
/// 注册一个 Dart 回调作为 JS 全局函数。
///
/// JS 调用 `name(args)` 时，dart_callback 被同步调用并返回结果给 JS。
/// 无需 Promise，JS 直接拿到返回值。
///
/// # Dart 示例
/// ```dart
/// await engine.register('add', (args) => args[0] + args[1]);
/// final result = await engine.eval(code: 'add(3, 4) + 10'); // 17
/// ```
pub async fn register(
    &self,
    name: String,
    dart_callback: impl Fn(String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<(), JsError> {
    // 1. 存入全局注册表
    crate::js_runtime::dart_callbacks::register(
        self.runtime_id,
        name.clone(),
        Arc::new(dart_callback),
    );
    // 2. 通知 worker 线程创建 NativeFunction
    worker::register(self.runtime_id, name)
}
```

同时新增 unregister:
```rust
#[frb(sync)]
pub fn unregister(&self, name: String) -> Result<(), JsError> {
    crate::js_runtime::dart_callbacks::unregister(self.runtime_id, &name);
    // 从 JS global 中删除
    worker::unregister(self.runtime_id, name)
}
```

### Step 6: 移除旧 API（Rust 侧）

**删除以下内容：**

| 文件 | 删除内容 |
|---|---|
| `rust/src/js_runtime/sync_bridge.rs` | **整个文件** |
| `rust/src/js_runtime/internal.rs` | `create_native_fn`, `create_sync_native_fn`, `next_call_id`, `CompletedCall`, `PendingCall`, `worker_locals` 模块, `register_dart_handler`, `unregister_dart_handler` |
| `rust/src/js_runtime/worker.rs` | `RegisterGlobalCallable`, `RegisterGlobalFunction`, `RegisterSyncFunction`, `PollCalls`, `ResolveCall`, `RejectCall` 变体 + 对应分发 + 对应 inner 函数 |
| `rust/src/api/engine.rs` | `register_global_callable`, `register_global_function`, `register_sync_function`, `register_dart_handler`, `poll_calls`, `resolve_call`, `reject_call`, `poll_sync_calls`, `resolve_sync_call`, `reject_sync_call` — 以及 `CompletedCall`, `SyncCall` 结构体 |
| `rust/src/api/runtime.rs` | 如果有对应的旧回调方法也一并移除 |

**修改 `rust/src/js_runtime/mod.rs`:**
```rust
pub(crate) mod dart_callbacks;
pub(crate) mod internal;
pub(crate) mod worker;
// sync_bridge 删除
```

### Step 7: 移除旧 API（Dart 侧）

**删除 `lib/src/api/js_callback_handler.dart`** — 整个文件不再需要。

**改 `lib/js_runtime.dart`** — 移除 export:
```dart
// 删除这行:
export 'src/api/js_callback_handler.dart';
```

FRB codegen 会自动更新 `lib/src/frb/api/engine.dart` 和 `lib/src/frb/api/runtime.dart`。
删除旧方法后，Dart 端的 `JsCallbackHandler`、`pollSyncCalls`、`resolveSyncCall` 等全部消失。

### Step 8: 错误处理增强

在所有新增代码中使用 KossJS 的错误模式：
- 构造：`JsNativeError::typ().with_message(msg).into()` / `JsNativeError::error().with_message(msg).into()`
- 已有代码中 `JsError::from_native(JsNativeError::typ().with_message(...))` → 简化为 `JsNativeError::typ().with_message(...).into()`

---

## 涉及文件总览

| 文件 | 操作 | 说明 |
|---|---|---|
| `rust/Cargo.toml` | 修改 | +tokio |
| `rust/src/js_runtime/mod.rs` | 修改 | +dart_callbacks, -sync_bridge |
| `rust/src/js_runtime/dart_callbacks.rs` | **新建** | 全局 dart_callback 注册表 + call_blocking |
| `rust/src/js_runtime/sync_bridge.rs` | **删除** | 整文件移除 |
| `rust/src/js_runtime/internal.rs` | 大幅修改 | 加 RuntimeState 字段, 加 create_dart_callback_fn, 删 create_native_fn/create_sync_native_fn/worker_locals/CompletedCall/PendingCall |
| `rust/src/js_runtime/worker.rs` | 大幅修改 | worker_loop 加 tokio rt, 加 Register 变体, 删 6 个旧变体 + inner 函数 |
| `rust/src/api/engine.rs` | 大幅修改 | 加 register/unregister, 删 10+ 旧方法, 删 CompletedCall/SyncCall 结构体 |
| `rust/src/api/runtime.rs` | 修改 | **仅删除**旧回调方法，不新增 register |
| `lib/js_runtime.dart` | 修改 | 删 js_callback_handler export |
| `lib/src/api/js_callback_handler.dart` | **删除** | 整文件移除 |
| `lib/src/frb/api/engine.dart` | 自动生成 | FRB codegen |
| `lib/src/frb/api/runtime.dart` | 自动生成 | FRB codegen |

---

## 验证

```bash
# 1. Rust 编译
cd packages/js_runtime/rust && cargo build

# 2. 重新生成 FRB 绑定
cd packages/js_runtime && flutter_rust_bridge_codegen generate

# 3. Dart 静态分析
cd packages/js_runtime && flutter analyze
```

功能验证：
```dart
final engine = JsEngine.create();

// 注册回调
await engine.register('add', (String argsJson) async {
  final args = jsonDecode(argsJson) as List;
  return jsonEncode(args[0] + args[1]);
});

// JS 调用
final result = await engine.eval(code: 'add(3, 4) + 10');
print(result.asIntegerSync); // 17

// 关闭
engine.close();
```

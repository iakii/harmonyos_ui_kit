# 包装 boa_engine — 有状态会话 + console + fetch

## Context

用户需要在 Dart 端调用带状态的 JS 运行时，支持 `console`（log/error/warn/info）和 `fetch` API。

## 核心技术发现

### FRB RustOpaque 不支持非 Send 类型
`RustOpaque<T>` 底层用 `Arc`，要求 `T: Send + Sync`。`boa_engine::Context` 使用 `Rc`（非 Send），**无法直接作为 FRB opaque struct 传递**。

### 解决方案：thread_local + RefCell 会话存储
由于 `#[frb(sync)]` 函数运行在 Dart 主 isolate 线程，且 `Context` 内部也使用 `thread_local!`，因此使用 `thread_local! + RefCell<HashMap<u64, Context>>` 管理多个运行时实例，用 `u64` ID 标识。

### boa_runtime 提供 fetch
`boa_runtime` 0.21.1 提供 `fetch` API，需要 `reqwest-blocking` feature 以使用 `BlockingReqwestFetcher`。

### Console 手动实现
`console` 非 boa_engine 内置，通过 `Context::register_global_property` + `ObjectInitializer::function` 将 `log/error/warn/info` 绑定为全局 `console` 对象的方法。

## 实现步骤

### 1. 修改 `rust/Cargo.toml` — 添加 boa_runtime 依赖

```toml
boa_runtime = { version = "0.21.1", features = ["reqwest-blocking"] }
```

### 2. 重写 `rust/src/api/boa.rs` — 有状态会话管理

核心函数：

```rust
use std::cell::RefCell;
use std::collections::HashMap;
use boa_engine::{Context, Source, JsResult, JsValue, js_string, NativeFunction, prelude::*};
use boa_engine::object::ObjectInitializer;
use boa_engine::property::Attribute;
use boa_engine::native_function::NativeFunction;

thread_local! {
    static RUNTIMES: RefCell<HashMap<u64, Context>> = RefCell::new(HashMap::new());
}

static NEXT_ID: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

/// 创建一个新的 JS 运行时并返回其 ID。
/// 预注册 console (log/error/warn/info) 和 fetch API。
pub fn create_runtime() -> u64 { ... }

/// 在指定运行时中执行 JS 代码，返回结果字符串。
pub fn eval_js(runtime_id: u64, code: String) -> Result<String, String> { ... }

/// 销毁指定运行时，释放资源。
pub fn destroy_runtime(runtime_id: u64) -> Result<(), String> { ... }
```

内部实现细节：

**Console 注册**（在 `create_runtime` 中调用）：

```rust
fn register_console(context: &mut Context) -> JsResult<()> {
    let log = NativeFunction::from_copy_closure(
        |_, args, ctx| {
            let msg = args.iter()
                .filter_map(|v| v.to_string(ctx).ok())
                .map(|s| s.to_std_string_escaped())
                .collect::<Vec<_>>()
                .join(" ");
            println!("[JS] {}", msg);
            Ok(JsValue::undefined())
        }
    );
    let error = NativeFunction::from_copy_closure(
        |_, args, ctx| {
            let msg = args.iter()
                .filter_map(|v| v.to_string(ctx).ok())
                .map(|s| s.to_std_string_escaped())
                .collect::<Vec<_>>()
                .join(" ");
            eprintln!("[JS Error] {}", msg);
            Ok(JsValue::undefined())
        }
    );
    let warn = NativeFunction::from_copy_closure(
        |_, args, ctx| {
            let msg = args.iter()
                .filter_map(|v| v.to_string(ctx).ok())
                .map(|s| s.to_std_string_escaped())
                .collect::<Vec<_>>()
                .join(" ");
            println!("[JS Warn] {}", msg);
            Ok(JsValue::undefined())
        }
    );
    let info = NativeFunction::from_copy_closure(
        |_, args, ctx| {
            let msg = args.iter()
                .filter_map(|v| v.to_string(ctx).ok())
                .map(|s| s.to_std_string_escaped())
                .collect::<Vec<_>>()
                .join(" ");
            println!("[JS Info] {}", msg);
            Ok(JsValue::undefined())
        }
    );

    let console = ObjectInitializer::new(context)
        .function(log, js_string!("log"), 1)
        .function(error, js_string!("error"), 1)
        .function(warn, js_string!("warn"), 1)
        .function(info, js_string!("info"), 1)
        .build();

    context.register_global_property(
        js_string!("console"),
        console,
        Attribute::all(),
    )
}
```

**Fetch 注册**（在 `create_runtime` 中调用）：

```rust
fn register_fetch(context: &mut Context) -> JsResult<()> {
    boa_runtime::register(
        (boa_runtime::FetchExtension(boa_runtime::BlockingReqwestFetcher::default()),),
        None,  // 全局注册
        context,
    )
}
```

### 3. 修改 `rust/src/api/mod.rs`

保持不变（`pub mod boa;` 已添加）。

### 4. 运行 codegen

```bash
cd third_library/t_lib && flutter_rust_bridge_codegen generate
```

### 5. 修改 `lib/lib.dart`

添加新 export（已完成部分）。

## 影响范围

| 文件 | 操作 |
|---|---|
| `rust/Cargo.toml` | 修改（添加 `boa_runtime` 依赖） |
| `rust/src/api/boa.rs` | **重写**（有状态会话 + console + fetch） |
| `rust/src/api/mod.rs` | 无需改动（已有 `pub mod boa;`） |
| `lib/src/frb/api/boa.dart` | codegen 自动更新 |
| `rust/src/frb_generated.rs` | codegen 自动更新 |
| `lib/lib.dart` | 无需改动（已有 export） |

## 验证

1. **Rust 编译**：`cd rust && cargo check` — 确认 compile 通过
2. **Codegen 生成**：`flutter_rust_bridge_codegen generate` — 确认无错误
3. **Dart 调用测试**：
   ```dart
   final id = createRuntime();
   print(await evalJs(runtimeId: id, code: "console.log('hello'); 1 + 1"));
   // 预期输出: [JS] hello
   // 预期返回: "2"
   print(await evalJs(runtimeId: id, code: "let x = 42; x * 2"));
   // 预期返回: "84"  (状态保持)
   destroyRuntime(runtimeId: id);
   ```

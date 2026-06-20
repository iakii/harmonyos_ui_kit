# Dart↔JS 双向通信通道实现计划

## Context

当前 `js_runtime` 插件已支持 Dart 通过 FRB 调用 Rust 执行 JS（`eval`/`call`），但缺少 JS 端主动向 Dart 发送消息的能力。需要实现一个基于消息队列的双向通道：

- **Dart → JS**: Dart 调用 `postMessage(event, data)` → 触发 `globalThis.__onDartMessage` 处理器
- **JS → Dart**: JS 调用 `__postMessage(event, data)` → 消息入队 → Dart 通过 `pollMessages()` 拉取

## 核心设计：消息队列模式

JS 执行在 Boa 上下文中是同步的，`RUNTIMES` 是 thread-local。方案：
1. 在 `RuntimeState` 中新增 `message_queue: Vec<JsMessage>`
2. `init_context` 中注册 Boa 原生函数 `__postMessage`，闭包捕获 `runtime_id`，调用时将消息推入对应运行时队列
3. Dart 端通过 `JsEngine.pollMessages()` 排空队列

## 修改文件清单

### 1. 新建 `rust/src/api/js_message.rs`

定义 `JsMessage` 结构体（FRB 可见）：

```rust
pub struct JsMessage {
    pub event: String,  // 事件名称，如 "log", "data"
    pub data: JsValue,  // 结构化的负载数据
}
```

### 2. 修改 `rust/src/api/mod.rs`

添加 `pub mod js_message;`

### 3. 修改 `rust/src/js_runtime/internal.rs`

- `RuntimeState` 新增字段 `message_queue: Vec<JsMessage>`
- `init_context` 签名改为 `init_context(max_memory: u64, runtime_id: u64)` → 传 runtime_id 供闭包捕获
- 新增 `register_message_channel(context, runtime_id)` 函数：
  - 使用 `NativeFunction::from_copy_closure` 创建原生函数（只捕获 `u64`，安全）
  - 通过 `context.register_global_builtin_callable("__postMessage", 2, fn)` 注册
  - 函数内部从 `RUNTIMES` 找到对应运行时，push `JsMessage` 入队
- `init_context` 中调用 `register_message_channel`

### 4. 修改 `rust/src/api/runtime.rs`

`create()` 方法中调用 `init_context` 时传入已生成的 `id`：
```rust
let state = internal::init_context(max_memory, id)?;
```

### 5. 修改 `rust/src/api/engine.rs`

在 `JsEngine` impl 块中新增三个方法：

- **`post_message`** (`#[frb(sync)]`): 
  - 将 `JsValue` data 用 `js_value_to_literal` 转为 JS 字面量
  - 构建并 eval `"globalThis.__onDartMessage('event', dataLit)"` 表达式
  - 若 handler 不存在（typeof 检查），返回 undefined，不抛异常
  - 返回 handler 的返回值 `JsValue`（可为 Promise 自动 resolve）

- **`poll_messages`** (`#[frb(sync)]`):
  - `std::mem::take(&mut state.message_queue)` 原子排空队列
  - 返回 `Vec<JsMessage>`

- **`has_messages`** (`#[frb(sync)]`):
  - 检查队列是否非空，轻量级轮询

### 6. 运行 `flutter_rust_bridge_codegen generate`

生成 Dart 端的 `JsMessage` 类和 `JsEngine` 新增方法。

### 7. 修改 `lib/js_runtime.dart`

添加 `export 'src/frb/api/js_message.dart';`

## 关键复用

- `js_value_to_literal()`（`js_value.rs:390`）— 将 JsValue 转为 JS 字面量字符串
- `JsValue::from_boa()`（`js_value.rs:226`）— Boa JsValue → 我们的 JsValue
- `RUNTIMES.with()` 模式（`engine.rs:90` 的 `call()` 方法）— 访问运行时状态的模式

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| JS 可能覆盖 `__postMessage` | 注册时设置 `writable: false, configurable: false` |
| 消息队列无限增长 | 初始版本不加限制，后续可加 `max_queue_size` |
| event 字符串注入 | 用 `replace('\'', "\\'")` + `replace('\\', "\\\\")` 做最小转义，后续可用 JSON.stringify |
| `__onDartMessage` 未定义时报错 | eval 时 `typeof ... === 'function'` 守卫 |

## 验证

1. `cd rust && cargo build` — 确保 Rust 编译通过
2. `flutter_rust_bridge_codegen generate` — 确保代码生成成功
3. `flutter pub get && flutter analyze` — Dart 静态分析通过
4. 编写简单的集成测试 JS 脚本：
   - JS 注册 `__onDartMessage` 处理器
   - Dart 调用 `postMessage`，JS 调用 `__postMessage`
   - Dart 调用 `pollMessages` 验证消息到达

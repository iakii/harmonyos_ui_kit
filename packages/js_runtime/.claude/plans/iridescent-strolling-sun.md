# 架构重设计计划：参考 FJS 重构 JS 运行时

## Context

当前 `js_runtime` 的 JS 运行时架构过于简单：只有一个 `JsRuntime` 结构体，`eval_js` 返回 `Result<String, String>`（纯字符串结果和错误），缺少结构化的值系统和错误处理。参考 FJS（基于 QuickJS 的 Flutter JS 引擎）的成熟架构设计，对本项目进行分层重构。

**核心问题**：
- 无类型化的 JS 值系统，eval 只能返回字符串
- 错误以纯 String 传递，无法程序化匹配和处理
- 无高层/底层 API 分层，所有用户面对同样的复杂度
- 内置模块配置不可控（始终注册 Console+Fetch+DOM）
- 无 eval 选项（strict mode、global scope 等）

**目标**：参考 FJS 两层 API 设计，构建 FRB 兼容的 JsValue/JsError 类型系统，让 Dart 端获得类型安全的 JS 互操作体验。

**引擎差异**：FJS 基于 QuickJS，本项目基于 Boa 0.21.1。字节码编译、部分 eval 选项、详细 GC 统计等 QuickJS 特性不可用，需适配。

## 核心设计决策

### 1. JsError：优先用 enum，回退用 struct

推荐使用 FRB enum with named variants（生成 Dart sealed class），但保留 struct 回退方案。

**方案 A（推荐）**：enum with 8 个核心变体
```rust
pub enum JsError {
    Syntax { message: String, line: Option<u32>, column: Option<u32> },
    Type { message: String },
    Reference { message: String },
    Runtime { message: String },
    MemoryLimit { message: String },
    StackOverflow { message: String },
    Internal { message: String },
    Generic { message: String },
}
```

**方案 B（回退）**：如果 FRB codegen 对复杂 enum 出问题，改用 struct：
```rust
pub struct JsError {
    pub code: String,       // "SYNTAX", "TYPE", etc.
    pub message: String,
}
```

### 2. JsValue：用 Box 打破递归

FRB v2 在处理递归类型时需要 `Box` 包装：
```rust
pub enum JsValue {
    None,
    Boolean(bool),
    Integer(i64),
    Float(f64),
    BigInt(String),
    String_(String),
    Bytes(Vec<u8>),
    Array(Vec<Box<JsValue>>),
    Object(Vec<(String, Box<JsValue>)>),
    Date(i64),
    Symbol(String),
}
```
`Box<JsValue>` 让 FRB 不再看到无限递归。Dart 端自动 de-ref 为 `List<JsValue>` / `Map<String, JsValue>`（近似）。

### 3. 不自定义 JsResult，直接用 Result<T, JsError>

FRB 原生支持 `Result<T, E>`。低层和高层 API 都返回 `Result<JsValue, JsError>`，区别在于高层 JsEngine 提供更多便利方法（call、declareModules 等）。

### 4. 内部状态隔离到 api/ 外部

将 `thread_local!` 和 `RuntimeState` 移到 `rust/src/js_runtime/internal.rs`（不在 `crate::api` 路径下），避免 FRB 误暴露私有类型。

## 文件结构

```
rust/src/
├── lib.rs                          # mod api; mod js_runtime; mod dom; mod frb_generated
├── frb_generated.rs                # [不变] 自动生成
├── dom.rs                          # [不变] DOM 模块
├── js_runtime/
│   ├── mod.rs                      # [新建] pub(crate) mod internal
│   └── internal.rs                 # [新建] RuntimeState, RUNTIMES, 辅助函数
└── api/
    ├── mod.rs                      # [修改] 新增 pub mod 声明
    ├── hello.rs                    # [不变]
    ├── boa.rs                      # [修改] 改为向后兼容的重导出 + 旧 API 适配
    ├── js_value.rs                 # [新建] JsValue 枚举 + Boa 互转
    ├── js_error.rs                 # [新建] JsError 类型 + 错误码
    ├── runtime.rs                  # [新建] JsRuntime 重构版（低层 API）
    ├── engine.rs                   # [新建] JsEngine 高层封装
    ├── eval_options.rs             # [新建] JsEvalOptions
    ├── builtin_options.rs          # [新建] JsBuiltinOptions + 预设
    └── module.rs                   # [新建] JsModule

lib/
├── lib.dart                        # [修改] 更新导出列表
└── src/
    ├── frb/                        # [重新生成] FRB 自动生成
    │   ├── frb_generated.dart
    │   ├── frb_generated.io.dart
    │   ├── frb_generated.web.dart
    │   └── api/
    │       ├── hello.dart
    │       ├── boa.dart            # 旧的 JsRuntime（保持不变）
    │       ├── js_value.dart
    │       ├── js_error.dart
    │       ├── runtime.dart
    │       ├── engine.dart
    │       ├── eval_options.dart
    │       ├── builtin_options.dart
    │       └── module.dart
    └── api/                        # [新建] 手写 Dart 便利层
        ├── boa.dart                # 重导出 + 旧 API 兼容
        └── js_value_ext.dart       # JsValue 便利扩展方法
```

## 各模块详细设计

### `js_value.rs` — JsValue 类型系统

```rust
pub enum JsValue {
    None,
    Boolean(bool),
    Integer(i64),
    Float(f64),
    BigInt(String),
    String_(String),
    Bytes(Vec<u8>),
    Array(Vec<Box<JsValue>>),
    Object(Vec<(String, Box<JsValue>)>),
    Date(i64),
    Symbol(String),
}

impl JsValue {
    pub fn type_name(&self) -> &'static str;
    pub fn is_none(&self) -> bool;
    pub fn is_boolean(&self) -> bool;
    pub fn is_number(&self) -> bool { matches!(self, Integer(_) | Float(_)) }
    // ... 其他判断/访问器
    pub(crate) fn from_boa(value: &boa_engine::JsValue, ctx: &mut Context) -> Self;
    pub(crate) fn to_boa(&self, ctx: &mut Context) -> Result<boa_engine::JsValue, JsError>;
    pub(crate) fn into_boa(self, ctx: &mut Context) -> Result<boa_engine::JsValue, JsError>;
}
```

### `js_error.rs` — 结构化错误

```rust
pub enum JsError {
    Syntax { message: String, line: Option<u32>, column: Option<u32> },
    Type { message: String },
    Reference { message: String },
    Runtime { message: String },
    MemoryLimit { message: String },
    StackOverflow { message: String },
    Internal { message: String },
    Generic { message: String },
}

impl JsError {
    pub fn code(&self) -> &'static str;  // 稳定错误码字符串
    pub fn message(&self) -> &str;       // 可读错误消息
}

// 从 Boa 错误转换
impl From<boa_engine::JsError> for JsError { ... }
impl From<boa_engine::JsNativeError> for JsError { ... }
```

### `runtime.rs` — JsRuntime 低层 API

```rust
pub struct JsRuntime { pub id: u64 }

pub struct JsRuntimeOptions {
    pub memory_limit: Option<u64>,
    pub info: Option<String>,
    pub builtins: Option<JsBuiltinOptions>,
}

impl JsRuntime {
    #[frb(sync)]
    pub fn create(options: Option<JsRuntimeOptions>) -> Self;

    #[frb(sync)]
    pub fn eval(&self, code: String) -> Result<JsValue, JsError>;

    #[frb(sync)]
    pub fn eval_with_options(
        &self, code: String, options: JsEvalOptions
    ) -> Result<JsValue, JsError>;

    #[frb(sync)]
    pub fn preload_module(&self, name: String, source: String) -> Result<(), JsError>;

    #[frb(sync)]
    pub fn memory_usage(&self) -> u64;

    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64);

    #[frb(sync)]
    pub fn run_gc(&self);  // Boa: clear_kept_objects()

    #[frb(sync)]
    pub fn release_memory(&self);  // 别名，同 run_gc

    #[frb(sync)]
    pub fn dispose(self) -> Result<(), JsError>;

    // 兼容旧 API
    #[frb(sync)]
    pub fn eval_js(&self, code: String) -> Result<String, String>;
}
```

### `engine.rs` — JsEngine 高层 API

```rust
pub struct JsEngine { runtime_id: u64 }

impl JsEngine {
    #[frb(sync)]
    pub fn create(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
        runtime_options: Option<JsRuntimeOptions>,
    ) -> Self;

    #[frb(sync)]
    pub fn eval(&self, code: String) -> Result<JsValue, JsError>;

    #[frb(sync)]
    pub fn declare_module(&self, module: JsModule) -> Result<(), JsError>;

    #[frb(sync)]
    pub fn declare_modules(&self, modules: Vec<JsModule>) -> Result<(), JsError>;

    #[frb(sync)]
    pub fn call(
        &self, module: String, method: String, params: Vec<JsValue>
    ) -> Result<JsValue, JsError>;

    #[frb(sync)]
    pub fn memory_usage(&self) -> u64;

    #[frb(sync)]
    pub fn run_gc(&self);

    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64);

    #[frb(sync)]
    pub fn close(self);
}
```

### `eval_options.rs`

```rust
pub struct JsEvalOptions {
    pub strict: bool,    // 默认 false，Boa 中通过 "use strict" 实现
    pub global: bool,    // 默认 false，Boa 默认就是全局作用域
}
// 注意：Boa 不支持 backtrace_barrier 和 promise toggle；
// promise 由 await_blocking 自动处理
```

### `builtin_options.rs`

```rust
pub struct JsBuiltinOptions {
    pub console: bool,
    pub fetch: bool,
    // Boa 原生支持：Console, Fetch（通过 boa_runtime extensions）
    // 以下在 Boa 中始终启用，字段用于 API 兼容：
    pub timers: bool,       // Boa 默认包含
    pub encoding: bool,     // Boa 默认包含
    pub url: bool,          // Boa 默认包含
}

impl JsBuiltinOptions {
    pub fn none() -> Self;
    pub fn essential() -> Self;  // console
    pub fn web() -> Self;        // console + fetch
    pub fn all() -> Self;        // console + fetch
}
```

### `module.rs`

```rust
pub struct JsModule {
    pub name: String,
    pub source: String,
}
```

### `js_runtime/internal.rs` — 内部状态（不暴露给 FRB）

保持现有的 `thread_local! RefCell<HashMap<u64, RuntimeState>>` 模式，添加工厂函数：

```rust
pub(crate) fn init_context(
    builtins: &JsBuiltinOptions,
    max_memory: u64,
) -> Result<RuntimeState, JsError>;
```

始终注册 DOM 模块（通过 `crate::dom::register_dom_module`）。

## 向后兼容策略

1. **`api/boa.rs`** 保留旧 API 作为 thin wrapper：
   - `JsRuntime::create(max_memory_bytes)` → 内部转为 `JsRuntimeOptions` 后调用 `runtime::JsRuntime::create()`
   - `eval_js()` → 调用新 `eval()` 并转回 String
   - `dispose()` → 委托给新 `dispose()`

2. **Dart 端** `lib/lib.dart` 同时导出新旧 API，旧代码无需改动。

3. FRB codegen 会为 `boa.rs` 中的旧 API 和 `runtime.rs` 中的新 API 都生成 Dart 代码。两者可共存。

## 实现步骤

### Phase 1：内部重构（不影响 API）
1. 创建 `rust/src/js_runtime/mod.rs` + `internal.rs`
2. 提取 thread_local 存储、RuntimeState、next_id、get_process_memory 到 internal.rs
3. 修改 `boa.rs`，改用 `js_runtime::internal` 的函数
4. 构建验证：`cargo build`

### Phase 2：核心类型
1. 创建 `js_value.rs`（JsValue 枚举 + Boa 互转 + 辅助方法）
2. 创建 `js_error.rs`（JsError 枚举 + 错误码 + From Boa errors）
3. 构建验证

### Phase 3：新 API 模块
1. 创建 `eval_options.rs`、`builtin_options.rs`、`module.rs`
2. 创建 `runtime.rs`（新 JsRuntime，使用 JsValue/JsError）
3. 创建 `engine.rs`（JsEngine 高层封装）
4. 更新 `api/mod.rs`
5. 更新 `lib.rs`（添加 `mod js_runtime`）
6. 构建验证

### Phase 4：FRB 代码生成
1. 运行 `flutter_rust_bridge_codegen generate`
2. 检查生成的 Dart 代码质量
3. 如果 enum 方案有问题，回退为 struct 方案

### Phase 5：Dart 便利层 + 向后兼容
1. 修改 `boa.rs` 为兼容层
2. 创建手写 Dart 扩展（`js_value_ext.dart`）
3. 更新 `lib/lib.dart` 导出
4. 运行 `flutter analyze`

### Phase 6：验证
1. 构建 Rust：`cargo build`
2. 运行 FRB codegen：`flutter_rust_bridge_codegen generate`
3. 运行 Flutter 分析：`flutter analyze`
4. 确认无编译错误

## 风险与缓解

| 风险 | 缓解 |
|------|------|
| FRB 不支持 `Vec<Box<JsValue>>` | 改用 JSON 序列化 bytes 传递复杂值 |
| JsError enum 13+ 变体 codegen 失败 | 回退为 struct（方案 B），即使 Dart 端失去模式匹配 |
| Boa call() 实现复杂 | 优先实现 eval + declare_module，call() 作为 stretch goal |
| `#[frb(sync)]` 阻塞 Dart isolate | 短期保持 sync（Boa 不可 Send），长期可考虑 spawn 到专用线程 |

## 不做什么

- ❌ 字节码编译/校验（Boa 不支持，QuickJS 专属）
- ❌ Bridge 双向调用机制（FRB 本身就是 bridge）
- ❌ 异步 Runtime/Context 分离（Boa !Send，不适用）
- ❌ 文件路径模块加载（安全风险，只支持源码字符串）
- ❌ Node.js 兼容模块（fs、net、crypto 等，超出范围）

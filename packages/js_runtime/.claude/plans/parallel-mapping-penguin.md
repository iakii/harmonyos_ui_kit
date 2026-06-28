# js_runtime 优化方案 — 实施计划

## Context

基于 `js_runtime优化方案.md` 的分析，结合实际代码现状评估后，选取 **4 个优化项** 分两个优先级实施。当前最突出的痛点：

1. **错误信息丢失**：Boa 引擎的 `to_string()` 包含 JS 堆栈，但 `classify_error()` 将其整个塞入 `message`，堆栈无法结构化提取。所有日志使用裸 `eprintln!`（无时间戳/级别）。
2. **缺少核心逻辑测试**：Rust 端零测试，`JsValue` 双向转换和 DOM/Encoding 模块的 HTML 解析/编解码函数无任何覆盖。
3. **模块注册硬编码**：`init_context()` 中逐个调用注册函数，每次添加新模块都要修改该函数。
4. **dart_callback 死锁风险**：当前通过 `tokio::block_on` 同步等待 Dart 响应，如果 Dart handler 中回调 `eval()` 会死锁，但没有文档明确警告。

## 实施范围总览

| 优先级 | 优化项 | 涉及文件数 | 预估工时 |
|--------|--------|-----------|---------|
| **P0** | 增强错误调试能力（stack 字段 + tracing + 上下文） | 8 个 Rust + 1 个 Cargo.toml + Dart 端自动生成 | 5h |
| **P0** | 异步通信死锁防护（文档约束） | 2 个（engine.rs + CLAUDE.md） | 0.5h |
| **P1** | 关键路径单元测试 | 3 个新增测试模块 | 4h |
| **P1** | 模块注册抽象（JsExtension trait） | 5 个（1 新增 + 4 修改） | 2h |

---

## 优化项 1: 增强错误调试能力 (P0)

### 1.1 JsError 增加 `stack` 字段

**背景**：Boa 的 `JsError` 在 `Display` 实现中已经包含调用栈（每帧以 `"\n    at "` 开头），当前 `classify_error()` 将 `err.to_string()` 全部放入 `message`，堆栈混在其中无法独立使用。

**方案**：在所有 9 个变体中增加 `stack: Option<String>` 字段，新增 `extract_message_and_stack()` 函数分离消息和堆栈。

**需要修改的文件**：

| 文件 | 改动 |
|------|------|
| `rust/src/api/js_error.rs` | (1) 所有变体增加 `stack: Option<String>` 字段；(2) `classify_error()` 所有返回分支增加 `stack: None`；(3) 新增 `extract_message_and_stack()` 函数；(4) `From<boa_engine::JsError>` 在分类前先提取堆栈并回填；(5) `Display` 适配新字段；(6) `code()` 和 `is_recoverable()` 无变更 |
| `rust/src/api/runtime.rs` | `validate()` / `validate_module()` 中 `JsError::Syntax { ... }` 构造补上 `stack: None`（4 处） |
| `rust/src/js_runtime/worker.rs` | 所有 `JsError::Internal { message: ... }` 和 `JsError::Cancelled { message: ... }` 构造点补上 `stack: None`（约 12 处） |
| `rust/src/js_runtime/internal.rs` | `check_memory_limit()` 中 `JsError::MemoryLimit` 构造补上 `stack: None` |
| `rust/src/api/js_value.rs` | `to_boa()` 中所有 `JsError::Internal { message: ... }` 构造补上 `stack: None`（约 7 处） |
| `lib/src/frb/api/js_error.dart` | **FRB codegen 自动重新生成**（不需手动编辑） |
| `lib/src/frb/api/js_error.freezed.dart` | **FRB codegen 自动重新生成**（不需手动编辑） |

**关键代码结构**：

```rust
// js_error.rs 新增函数
fn extract_message_and_stack(full: &str) -> (String, Option<String>) {
    // Boa Display 格式:
    //   "TypeError: message\n    at func1 (file:line:col)\n    at func2 ..."
    if let Some(pos) = full.find("\n    at ") {
        let message = full[..pos].to_string();
        let stack = Some(full[pos + 1..].to_string()); // 去掉开头的 \n
        (message, stack)
    } else {
        (full.to_string(), None)
    }
}
```

**注意事项**：
- ⚠️ **这是一个破坏性 API 变更**：Dart 端 `JsError.when()` 等模式匹配方法签名会变，所有上游调用方需要适配
- 修复所有构造点的关键是：编译一次，挨个修复编译错误（编译器会指出所有不匹配的地方）
- `extract_message_and_stack` 的正则/查找逻辑仅依赖于 Boa 的 Display 格式，如果未来 Boa 升级改变了格式，需要同步调整

### 1.2 引入 tracing 替代 eprintln!

**背景**：当前 11 处 `eprintln!` 无时间戳、无级别，生产中无法按需开关。

**方案**：添加 `tracing` + `tracing-subscriber` 依赖，在 `lib.rs` 中提供 `init_logging()` 初始化函数，在 `engine.rs` 中暴露 `set_log_level()` FRB 方法。

**需要修改的文件**：

| 文件 | 改动 |
|------|------|
| `rust/Cargo.toml` | 添加 `tracing = "0.1"` 和 `tracing-subscriber = { version = "0.3", features = ["env-filter"] }` |
| `rust/src/lib.rs` | 新增 `pub fn init_logging()` — 初始化 tracing subscriber，默认级别 `warn`，支持 `RUST_LOG` 环境变量覆盖 |
| `rust/src/api/engine.rs` | 新增 `#[frb(sync)] pub fn set_log_level(level: String)` 方法；`eprintln!("Warning: Failed to preload module...")` → `tracing::warn!` |
| `rust/src/js_runtime/internal.rs` | 4 处 `eprintln!("Warning: ...")` → `tracing::warn!` |
| `rust/src/js_runtime/worker.rs` | 11 处 `eprintln!` → 按语义映射为 `tracing::info!` / `warn!` / `error!` |

**eprintln! → tracing 映射规则**：

| 原位置 | 语义 | 映射为 |
|--------|------|--------|
| `send_and_wait: cancelled` | 正常流程事件 | `tracing::info!` |
| `cancel_eval: gen X → Y` | 正常流程事件 | `tracing::info!` |
| `cancel_eval: runtime not found` | 可恢复异常 | `tracing::warn!` |
| `cancel_eval: WORKERS lock poisoned` | 严重异常 | `tracing::error!` |
| `Failed to create tokio runtime` | 严重异常 | `tracing::error!` |
| `Failed to init context` | 严重异常 | `tracing::error!` |
| `Warning: Failed to preload module` | 可恢复异常 | `tracing::warn!` |
| `Warning: {e}` (internal.rs 中 4 处) | 可恢复异常 | `tracing::warn!` |

**关键代码**：

```rust
// rust/src/lib.rs 新增
pub fn init_logging() {
    use tracing_subscriber::EnvFilter;
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("js_runtime=warn"))
        )
        .with_target(false)
        .without_time() // 在移动端可能无时钟，通过环境变量控制
        .try_init()
        .ok(); // 多次调用忽略（Once 保证）
}

// rust/src/api/engine.rs 新增
#[frb(sync)]
pub fn set_log_level(level: String) -> Result<(), String> {
    use tracing_subscriber::EnvFilter;
    let filter = format!("js_runtime={level}");
    // ... 使用 reload 或直接设置
}
```

**注意事项**：
- `tracing` 本身不输出，必须有 subscriber。如果 Dart 端忘记调用 `init_logging()`，日志将静默丢失
- 在 release 构建中，tracing 宏是零成本抽象，仅在 subscriber 启用时有开销
- `try_init()` 保证多次调用安全

### 1.3 Worker 命令处理错误增强

**方案**：在 `worker_loop` 中，对于返回给调用方的 `JsError::Internal`，统一附加运行时 ID 和命令描述，便于定位问题。

**修改文件**：仅 `rust/src/js_runtime/worker.rs`

**实现方式**：
```rust
// worker.rs 新增辅助函数
fn enrich_internal_error(e: JsError, runtime_id: u64, cmd: &str) -> JsError {
    match e {
        JsError::Internal { message, stack } => JsError::Internal {
            message: format!("[runtime={runtime_id}][cmd={cmd}] {message}"),
            stack,
        },
        other => other,
    }
}
```

在每个 match 分支的 `reply.send(result)` 处应用。

---

## 优化项 2: 异步通信死锁防护 (P0)

**纯文档变更，不涉及代码修改**。

**需要增加文档约束的文件**：

| 文件 | 改动 |
|------|------|
| `rust/src/api/engine.rs` | `register()` 方法的 rustdoc 中增加 **"死锁警告"** 小节，说明 Dart handler 中禁止调用 `eval()` 等需要 worker 响应的方法，给出错误示例和正确模式 |
| `CLAUDE.md` | 在 "JS-Dart 回调模式" 后新增 **"死锁风险与避免"** 小节，列出禁止操作、允许操作、推荐模式（`evalRaw` + `runJobs`） |

**关键约束规则**：
- ✅ 在 Dart handler 中允许：纯 Dart 计算、HTTP 请求、数据库操作
- ❌ 在 Dart handler 中禁止：`eval()` / `register()` / `unregister()` / `call()` 等需要相同 runtime_id worker 响应的操作
- 💡 推荐：需要 `await registeredCallback()` 的场景使用 `evalRaw()` 代替 `eval()`

---

## 优化项 3: 关键路径单元测试 (P1)

### 3.1 js_value.rs 测试

**文件**：`rust/src/api/js_value.rs`（文件末尾新增 `#[cfg(test)] mod tests { ... }`）

**测试辅助**：
```rust
fn test_context() -> Context {
    Context::default()
}
```

**测试用例清单**（约 25-30 个）：

| 类别 | 测试函数 | 验证点 |
|------|----------|--------|
| Boa→FRB 基础类型 | `test_from_boa_null` | `JsValue::None` |
| | `test_from_boa_boolean_true/false` | `Boolean(true/false)` |
| | `test_from_boa_integer_*` (3 个: 正/负/零) | `Integer(N)` |
| | `test_from_boa_float_*` (2 个: 小数/科学计数) | `Float(N)` |
| | `test_from_boa_string_*` (3 个: ASCII/中文/空) | `String_(s)` |
| | `test_from_boa_bigint` | `BigInt(s)` |
| Boa→FRB 结构化 | `test_from_boa_simple_array` | `Array([1,2,3])` |
| | `test_from_boa_nested_array` | `Array([Array(...)])` |
| | `test_from_boa_empty_array` | `Array([])` |
| | `test_from_boa_simple_object` | `Object([("a", 1)])` |
| | `test_from_boa_nested_object` | `Object([("a", Object(...))])` |
| | `test_from_boa_empty_object` | `Object([])` |
| 类型判断 | `test_type_name_null/boolean/number/string/array/object` | 正确返回类型名 |
| | `test_is_*` 系列 (10 个) | `is_boolean()`, `is_number()` 等 |
| 访问器 | `test_as_boolean_some/none` | 正确提取/返回 None |
| | `test_as_integer_some/none` | 正确提取 |
| | `test_as_number_from_integer` | `Integer(1)` → `as_number()` = `1.0` |
| | `test_as_float_some/none` | 正确提取 |
| 构造器 | `test_from_bool/from_int/from_float/from_string/from_str/null` | 各工厂方法正确构造 |
| | `test_clone` | 递归克隆正确 |
| 辅助函数 | `test_is_valid_js_identifier_valid` | `a`, `_a`, `$a`, `a1`, `a1b` → true |
| | `test_is_valid_js_identifier_invalid` | `""`, `1a`, `a-b`, `a.b` → false |
| 往返测试 | `test_roundtrip_null/boolean/integer/float/string` | `from_boa(to_boa(x))` = x |

### 3.2 dom.rs 测试

**文件**：`rust/src/dom.rs`（文件末尾新增 `#[cfg(test)] mod tests { ... }`）

**测试用例**（约 8-10 个）：

| 测试函数 | 验证点 |
|----------|--------|
| `test_extract_element_basic` | 解析 `<div id='x' class='y'>Hello</div>` 的基本属性 |
| `test_extract_element_nested` | 嵌套 HTML 的 innerHtml 和 text 正确 |
| `test_extract_element_empty` | 空元素处理 |
| `test_register_dom_module_succeeds` | Context::default() 下注册成功 |
| `test_query_selector_all` | 通过 JS eval 调用 `import('dom')` 验证整个链路 |
| `test_query_selector_single` | `querySelector` 返回单元素 |
| `test_query_selector_not_found` | `querySelector` 返回 null |
| `test_query_selector_invalid_css` | 非法 CSS 选择器抛出 |

### 3.3 encoding.rs 测试

**文件**：`rust/src/encoding.rs`（文件末尾新增 `#[cfg(test)] mod tests { ... }`）

**测试用例**（约 10-12 个）：

| 测试函数 | 验证点 |
|----------|--------|
| `test_find_encoding_utf8` | `find_encoding("UTF-8")` / `"utf-8"` 存在 |
| `test_find_encoding_gbk` | `find_encoding("GBK")` / `"gb2312"` 存在（别名） |
| `test_find_encoding_big5` | `find_encoding("Big5")` 存在 |
| `test_find_encoding_nonexistent` | 不存在返回 None |
| `test_decode_gbk` | `[196, 227, 186, 195]` → `"你好"` |
| `test_encode_gbk` | `"你好"` → `[196, 227, 186, 195]` |
| `test_decode_shift_jis` | 日文编解码 |
| `test_detect_bom_utf8` | `[0xEF, 0xBB, 0xBF, ...]` → `"UTF-8"` |
| `test_detect_bom_utf16le` | `[0xFF, 0xFE, ...]` → `"UTF-16LE"` |
| `test_detect_no_bom` | 无 BOM → null |
| `test_register_encoding_module_succeeds` | 注册成功 |

**Cargo.toml 变更**：无需添加 dev-dependencies（所有依赖已在 `[dependencies]` 中）。

**注意事项**：
- 测试 `register_*_module` 需要使用 `Context::builder().module_loader(Rc::new(MapModuleLoader::new())).build()` 创建的 context，而不能用 `Context::default()`
- 通过 JS eval 验证模块的端到端测试需要构造完整的 Boa Context

---

## 优化项 4: 模块注册抽象 (P1)

**背景**：DOM 和 Encoding 模块注册遵循完全相同的 4 步模式（创建函数 → 构建 exports → downcast loader → insert），可以在不改变行为的前提下抽象为 trait。

**方案**：在 `js_runtime` 目录下新增 `extensions.rs`，定义 `JsExtension` trait，为 DOM/Encoding 实现该 trait，修改 `init_context()` 遍历注册。

**需要修改/新增的文件**：

| 文件 | 改动 |
|------|------|
| `rust/src/js_runtime/extensions.rs` | **新增**：定义 `JsExtension` trait |
| `rust/src/js_runtime/mod.rs` | 新增 `pub(crate) mod extensions;` |
| `rust/src/dom.rs` | 新增 `DomExtension` unit struct + 实现 `JsExtension`（调用现有 `register_dom_module`） |
| `rust/src/encoding.rs` | 新增 `EncodingExtension` unit struct + 实现 `JsExtension`（调用现有 `register_encoding_module`） |
| `rust/src/js_runtime/internal.rs` | `init_context()` 中：用 `builtin_extensions()` 遍历替代逐个硬编码调用 |

**trait 定义**：

```rust
// rust/src/js_runtime/extensions.rs
use boa_engine::Context;

pub(crate) trait JsExtension {
    /// 扩展名称（用于日志/错误报告），如 "dom"、"encoding"。
    fn name(&self) -> &'static str;

    /// 注册此扩展到给定的 Boa 上下文。失败返回错误描述。
    fn register(&self, context: &mut Context) -> Result<(), String>;
}
```

**init_context() 修改**：
```rust
// 替换当前的逐个硬编码调用:
//   if let Err(e) = crate::dom::register_dom_module(...)
//   if let Err(e) = crate::encoding::register_encoding_module(...)
//
// 改为:
for ext in builtin_extensions() {
    if let Err(e) = ext.register(&mut context) {
        tracing::warn!("扩展 `{}` 注册失败: {e}", ext.name());
    }
}

// builtin_extensions() 定义在 internal.rs:
fn builtin_extensions() -> Vec<Box<dyn JsExtension>> {
    vec![
        Box::new(crate::dom::DomExtension),
        Box::new(crate::encoding::EncodingExtension),
    ]
}
```

**向后兼容**：`register_dom_module()` 和 `register_encoding_module()` 保持 `pub` 不变，外部代码仍可直接调用。

---

## 实施顺序

```
第 1 步 (0.5h) → 优化项 2（死锁文档）        零风险，直接写文档
第 2 步 (2h)   → 优化项 4（JsExtension trait）  低风险，纯内部重构，不改变 API
第 3 步 (2h)   → 优化项 1.2（tracing 日志）     低风险，替换实现，不改 API
第 4 步 (1h)   → 优化项 1.3（错误上下文增强）   低风险，增量改进
第 5 步 (2h)   → 优化项 1.1（JsError stack）    高风险，破坏性 API 变更
第 6 步 (4h)   → 优化项 3（单元测试）           可与其他步骤并行
```

## 验证方案

### 编译验证
```bash
# Rust 编译（含测试）
cd rust && cargo build && cargo test

# Dart 端 codegen + 分析
cd .. && flutter_rust_bridge_codegen generate && flutter analyze

# 上游 Flutter 应用编译
cd ../.. && flutter analyze
```

### 功能验证
1. **错误堆栈**：在测试 JS 代码中故意抛出异常（如 `throw new Error('test')`），检查 Dart 端 `JsError.when(runtime: (msg, stack) => ...)` 中 `stack` 是否包含调用栈帧
2. **tracing 日志**：在 Dart 端调用 `setLogLevel("debug")` 后触发 eval 取消，确认日志输出包含级别和时间戳
3. **单元测试**：`cargo test` 全部通过
4. **模块注册**：验证 `import('dom')` 和 `import('encoding')` 在 JsExtension trait 重构后仍正常工作

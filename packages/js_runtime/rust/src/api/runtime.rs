//! JsRuntime —— 低层 JS 运行时 API。
//!
//! 参考 FJS 的 `JsRuntime` 设计，返回类型化的 [JsValue] 和结构化的 [JsError]。
//! 适合需要精细控制运行时生命周期的场景。
//!
//! 高层封装见 [super::engine::JsEngine]。

use crate::api::builtin_options::JsBuiltinOptions;
use crate::api::eval_options::JsEvalOptions;
use crate::api::js_error::JsError;
use crate::api::js_value::JsValue;
use crate::js_runtime::internal;
use boa_ast::scope::Scope;
use boa_engine::Source;
use boa_interner::Interner;
use boa_parser::Parser;
use flutter_rust_bridge::frb;

/// 运行时选项。
pub struct JsRuntimeOptions {
    /// 内存上限（字节），`0` 或 `null` 表示不限制
    pub memory_limit: Option<u64>,
    /// 运行时标识名称（用于调试）
    pub info: Option<String>,
    /// 内置模块配置，默认使用 [JsBuiltinOptions::essential]
    pub builtins: Option<JsBuiltinOptions>,
}

impl Default for JsRuntimeOptions {
    fn default() -> Self {
        Self {
            memory_limit: None,
            info: None,
            builtins: Some(JsBuiltinOptions::essential()),
        }
    }
}

/// JS 运行时句柄。
///
/// 通过 [JsRuntime::create] 创建，使用完毕后调用 [JsRuntime::dispose] 释放。
/// 每次调用会占用资源（Boa 上下文），建议复用。
pub struct JsRuntime {
    pub id: u64,
}

impl JsRuntime {
    /// 创建一个新的 JS 运行时。
    ///
    /// # 参数
    /// - `options`: 运行时配置选项，`null` 使用默认值（无内存限制 + essential 内置模块）。
    #[frb(sync)]
    pub fn create(options: Option<JsRuntimeOptions>) -> Self {
        let opts = options.unwrap_or_default();
        let id = internal::next_id();
        let max_memory = opts.memory_limit.unwrap_or(0);

        let state = internal::init_context(max_memory, id)
            .expect("init_context should succeed");

        internal::RUNTIMES.with(|map| {
            map.borrow_mut().insert(id, state);
        });

        Self { id }
    }

    // ─── 代码执行 ────────────────────────────────────────

    /// 执行 JavaScript 代码，返回类型化的 [JsValue]。
    ///
    /// 自动解析 Promise（通过 `await_blocking`）。
    /// 如已设置内存上限，执行前后会进行内存检查。
    ///
    /// # 错误
    /// - [JsError::Syntax] — 代码解析失败
    /// - [JsError::Runtime] — 执行期间抛出异常
    /// - [JsError::MemoryLimit] — 内存超限
    #[frb(sync)]
    pub fn eval(&self, code: String) -> Result<JsValue, JsError> {
        self.eval_internal(&code, &JsEvalOptions::default())
    }

    /// 带选项执行 JavaScript 代码。
    ///
    /// `options` 控制 strict mode、global scope 等行为。
    /// 详见 [JsEvalOptions]。
    #[frb(sync)]
    pub fn eval_with_options(
        &self,
        code: String,
        options: JsEvalOptions,
    ) -> Result<JsValue, JsError> {
        self.eval_internal(&code, &options)
    }

    fn eval_internal(&self, code: &str, options: &JsEvalOptions) -> Result<JsValue, JsError> {
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Runtime {} not found", self.id),
                })?;

            // 内存检查（执行前）
            internal::check_memory_limit(state)
                .map_err(|msg| JsError::MemoryLimit { message: msg })?;

            // 应用 eval 选项
            let source = options.apply(code);

            // 执行
            let result = match state.context.eval(Source::from_bytes(source.as_bytes())) {
                Ok(value) => {
                    // 自动解析 Promise
                    let resolved = if let Some(promise) = value.as_promise() {
                        match promise.await_blocking(&mut state.context) {
                            Ok(v) => v,
                            Err(e) => {
                                return Err(JsError::from(e));
                            }
                        }
                    } else {
                        value
                    };
                    JsValue::from_boa(&resolved, &mut state.context)
                }
                Err(e) => {
                    return Err(JsError::from(e));
                }
            };

            // 更新内存估算
            let code_bytes = code.len() as u64;
            state.total_code_bytes += code_bytes;
            state.estimated_memory += code_bytes;

            // 内存检查（执行后）
            internal::check_memory_limit(state)
                .map_err(|msg| JsError::MemoryLimit { message: msg })?;

            Ok(result)
        })
    }

    // ─── 模块管理 ────────────────────────────────────────

    /// 预加载一个 ES 模块，使其可通过 `import('name')` 动态导入。
    #[frb(sync)]
    pub fn preload_module(&self, name: String, source: String) -> Result<(), JsError> {
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Runtime {} not found", self.id),
                })?;

            let module = internal::parse_module(&name, &source, &mut state.context)
                .map_err(|e| JsError::Internal { message: e })?;

            let loader = internal::get_module_loader(&mut state.context)
                .map_err(|e| JsError::Internal { message: e })?;

            loader.insert(&name, module);

            let bytes = source.len() as u64;
            state.total_module_bytes += bytes;
            state.estimated_memory += bytes;

            Ok(())
        })
    }

    // ─── 内存管理 ────────────────────────────────────────

    /// 获取当前运行时的估算内存用量（字节）。
    #[frb(sync)]
    pub fn memory_usage(&self) -> u64 {
        internal::RUNTIMES.with(|map| {
            map.borrow()
                .get(&self.id)
                .map(|s| s.estimated_memory)
                .unwrap_or(0)
        })
    }

    /// 获取进程的物理内存用量（字节），平台不支持时返回 `0`。
    #[frb(sync)]
    pub fn total_memory_usage() -> u64 {
        internal::get_process_memory().unwrap_or(0)
    }

    /// 设置内存上限（字节），`0` 表示不限制。
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64) {
        internal::RUNTIMES.with(|map| {
            if let Some(state) = map.borrow_mut().get_mut(&self.id) {
                state.max_memory = limit_bytes;
            }
        });
    }

    /// 触发垃圾回收。
    ///
    /// 调用 `boa_gc::force_collect()` 执行完整的标记-清除 GC，
    /// 同时清理 WeakRef 保持的对象。
    #[frb(sync)]
    pub fn run_gc(&self) {
        internal::RUNTIMES.with(|map| {
            if let Some(state) = map.borrow_mut().get_mut(&self.id) {
                // 完整 GC 循环（标记-清除）
                boa_gc::force_collect();
                // 清理 WeakRef 保持的对象
                state.context.clear_kept_objects();
                // 重置代码估算值（模块保持不变）
                state.estimated_memory = state.total_module_bytes;
                state.total_code_bytes = 0;
            }
        });
    }

    /// 释放内存 —— 同 [run_gc](Self::run_gc)。
    #[frb(sync)]
    pub fn release_memory(&self) {
        self.run_gc();
    }

    // ─── 生命周期 ────────────────────────────────────────

    /// 销毁运行时，释放所有关联资源。
    ///
    /// 调用后该句柄不再可用。
    #[frb(sync)]
    pub fn dispose(self) -> Result<(), JsError> {
        internal::RUNTIMES.with(|map| {
            map.borrow_mut()
                .remove(&self.id)
                .map(|_| ())
                .ok_or_else(|| JsError::Internal {
                    message: format!("Runtime {} not found", self.id),
                })
        })
    }
}

// ─── 语法校验（不执行）──────────────────────────────────

impl JsRuntime {
    /// 校验 JavaScript 代码语法，**不执行代码**。
    ///
    /// 使用 `boa_parser` 解析为 Script AST，成功返回 `Ok(())`，
    /// 失败返回包含行列信息的 [JsError::Syntax]。
    ///
    /// 与 `eval()` 不同，此方法不会创建或修改任何 JS 运行时状态。
    #[frb(sync)]
    pub fn validate(code: String) -> Result<(), JsError> {
        let scope = Scope::new_global();
        let mut interner = Interner::new();
        let source = Source::from_bytes(code.as_bytes());
        let mut parser = Parser::new(source);

        match parser.parse_script(&scope, &mut interner) {
            Ok(_) => Ok(()),
            Err(e) => {
                let msg = e.to_string();
                match e {
                    boa_parser::Error::Expected { span, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(span.start().line_number()),
                            column: Some(span.start().column_number()),
                        })
                    }
                    boa_parser::Error::Unexpected { span, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(span.start().line_number()),
                            column: Some(span.start().column_number()),
                        })
                    }
                    boa_parser::Error::General { position, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(position.line_number()),
                            column: Some(position.column_number()),
                        })
                    }
                    _ => Err(JsError::Syntax {
                        message: msg,
                        line: None,
                        column: None,
                    }),
                }
            }
        }
    }

    /// 校验 ES 模块语法，**不执行代码**。
    ///
    /// 使用 `boa_parser` 解析为 Module AST。
    /// 适用于在 `preload_module()` 之前预检模块源码。
    #[frb(sync)]
    pub fn validate_module(name: String, source: String) -> Result<(), JsError> {
        let scope = Scope::new_global();
        let mut interner = Interner::new();
        let src = Source::from_bytes(source.as_bytes());
        let mut parser = Parser::new(src);

        match parser.parse_module(&scope, &mut interner) {
            Ok(_) => Ok(()),
            Err(e) => {
                let msg = format!("[{name}] {e}");
                match e {
                    boa_parser::Error::Expected { span, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(span.start().line_number()),
                            column: Some(span.start().column_number()),
                        })
                    }
                    boa_parser::Error::Unexpected { span, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(span.start().line_number()),
                            column: Some(span.start().column_number()),
                        })
                    }
                    boa_parser::Error::General { position, .. } => {
                        Err(JsError::Syntax {
                            message: msg,
                            line: Some(position.line_number()),
                            column: Some(position.column_number()),
                        })
                    }
                    _ => Err(JsError::Syntax {
                        message: msg,
                        line: None,
                        column: None,
                    }),
                }
            }
        }
    }
}

// ─── 向后兼容方法 ────────────────────────────────────────

impl JsRuntime {
    /// 旧版 create 的别名：使用简单的内存限制参数。
    ///
    /// 新代码推荐使用 `JsRuntime::create(options:)`。
    #[frb(sync)]
    pub fn create_legacy(max_memory_bytes: Option<u64>) -> Self {
        let opts = JsRuntimeOptions {
            memory_limit: max_memory_bytes,
            ..Default::default()
        };
        Self::create(Some(opts))
    }

    /// 旧版 eval_js 的别名：返回字符串而非 [JsValue]。
    ///
    /// 新代码推荐使用 `eval(code)` 获取类型化的 [JsValue]。
    #[frb(sync)]
    pub fn eval_js_str(&self, code: String) -> Result<String, String> {
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.id)
                .ok_or_else(|| format!("Runtime {} not found", self.id))?;

            let result = internal::eval_and_resolve(&code, state)?;

            let code_bytes = code.len() as u64;
            state.total_code_bytes += code_bytes;
            state.estimated_memory += code_bytes;

            internal::check_memory_limit(state)?;

            Ok(result)
        })
    }
}

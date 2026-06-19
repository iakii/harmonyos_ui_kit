//! JsEngine —— 高层 JS 引擎 API。
//!
//! 参考 FJS 的 `JsEngine` 设计，封装运行时生命周期，
//! 提供更简洁的 API 供日常使用。
//!
//! 低层 API 见 [super::runtime::JsRuntime]。

use crate::api::builtin_options::JsBuiltinOptions;
use crate::api::eval_options::JsEvalOptions;
use crate::api::js_error::JsError;
use crate::api::js_value::{js_value_to_literal, JsValue};
use crate::api::module::JsModule;
use crate::api::runtime::{JsRuntime, JsRuntimeOptions};
use crate::js_runtime::internal;
use flutter_rust_bridge::frb;

/// 高层 JS 引擎。
///
/// 内部持有一个 [JsRuntime]，自动管理生命周期。
/// 方法失败时返回 [JsError]。
pub struct JsEngine {
    pub runtime_id: u64,
}

impl JsEngine {
    /// 创建 JS 引擎。
    ///
    /// # 参数
    /// - `builtins`: 内置模块配置，默认 [JsBuiltinOptions::essential]
    /// - `modules`: 创建后立即注册的模块列表
    /// - `runtime_options`: 底层运行时选项（内存上限等）
    #[frb(sync)]
    pub fn create(
        builtins: Option<JsBuiltinOptions>,
        modules: Option<Vec<JsModule>>,
        runtime_options: Option<JsRuntimeOptions>,
    ) -> Self {
        let mut opts = runtime_options.unwrap_or_default();
        if let Some(b) = builtins {
            opts.builtins = Some(b);
        }

        let runtime = JsRuntime::create(Some(opts));
        let id = runtime.id;

        // 注册初始模块
        if let Some(mods) = modules {
            for m in mods {
                if let Err(e) = runtime.preload_module(m.name, m.source) {
                    eprintln!("Warning: Failed to preload module: {e}");
                }
            }
        }

        // JsRuntime::create 已将状态存入 RUNTIMES，我们只需保留 id
        std::mem::forget(runtime);

        Self { runtime_id: id }
    }

    /// 执行 JavaScript 代码，返回类型化的 [JsValue]。
    #[frb(sync)]
    pub fn eval(&self, code: String) -> Result<JsValue, JsError> {
        self.runtime().eval(code)
    }

    /// 带选项执行 JavaScript 代码。
    #[frb(sync)]
    pub fn eval_with_options(
        &self,
        code: String,
        options: JsEvalOptions,
    ) -> Result<JsValue, JsError> {
        self.runtime().eval_with_options(code, options)
    }

    /// 调用已注册模块的导出函数。
    ///
    /// # 参数
    /// - `module`: 模块名称（已通过 [declare_module](Self::declare_module) 注册）
    /// - `method`: 导出函数名
    /// - `params`: 参数列表
    #[frb(sync)]
    pub fn call(
        &self,
        module: String,
        method: String,
        params: Vec<JsValue>,
    ) -> Result<JsValue, JsError> {
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.runtime_id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Engine runtime {} not found", self.runtime_id),
                })?;

            // 构建参数 JS 字面量
            let mut args_parts = Vec::with_capacity(params.len());
            for param in &params {
                let lit = js_value_to_literal(param, &mut state.context)?;
                args_parts.push(lit);
            }
            let args_code = args_parts.join(", ");

            // 构建调用表达式
            let code = format!(
                "await import('{module}').then(function(m) {{ return m.{method}({args_code}); }})"
            );

            // 执行
            let result = state
                .context
                .eval(boa_engine::Source::from_bytes(code.as_bytes()))
                .map_err(JsError::from)?;

            // 解析 Promise
            let resolved = if let Some(promise) = result.as_promise() {
                promise
                    .await_blocking(&mut state.context)
                    .map_err(JsError::from)?
            } else {
                result
            };

            Ok(JsValue::from_boa(&resolved, &mut state.context))
        })
    }

    /// 注册一个 ES 模块。
    #[frb(sync)]
    pub fn declare_module(&self, module: JsModule) -> Result<(), JsError> {
        self.runtime().preload_module(module.name, module.source)
    }

    /// 批量注册 ES 模块。同一批中的模块名不允许重复。
    #[frb(sync)]
    pub fn declare_modules(&self, modules: Vec<JsModule>) -> Result<(), JsError> {
        for m in modules {
            self.runtime().preload_module(m.name, m.source)?;
        }
        Ok(())
    }

    /// 获取内存估算用量（字节）。
    #[frb(sync)]
    pub fn memory_usage(&self) -> u64 {
        self.runtime().memory_usage()
    }

    /// 触发垃圾回收。
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.runtime().run_gc();
    }

    /// 设置内存上限（字节），`0` 表示不限制。
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64) {
        self.runtime().set_memory_limit(limit_bytes);
    }

    /// 关闭引擎，释放所有资源。
    #[frb(sync)]
    pub fn close(self) -> Result<(), JsError> {
        let runtime = JsRuntime {
            id: self.runtime_id,
        };
        runtime.dispose()
    }

    // ─── 内部辅助 ────────────────────────────────────────

    fn runtime(&self) -> JsRuntime {
        JsRuntime {
            id: self.runtime_id,
        }
    }
}

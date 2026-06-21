//! JsEngine —— 高层 JS 引擎 API。
//!
//! 参考 FJS 的 `JsEngine` 设计，封装运行时生命周期，
//! 提供更简洁的 API 供日常使用。
//!
//! 低层 API 见 [super::runtime::JsRuntime]。

use crate::api::builtin_options::JsBuiltinOptions;
use crate::api::eval_options::JsEvalOptions;
use crate::api::js_error::JsError;
use crate::api::js_value::JsValue;
use crate::api::module::JsModule;
use crate::api::runtime::{JsRuntime, JsRuntimeOptions};
use crate::js_runtime::internal;
use crate::js_runtime::worker;
use flutter_rust_bridge::frb;

/// 高层 JS 引擎。
///
/// 内部持有一个 JsRuntime（专用后台工作线程），自动管理生命周期。
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

        // 注册初始模块（通过 worker channel）
        if let Some(mods) = modules {
            for m in mods {
                if let Err(e) = worker::preload_module(id, m.name, m.source) {
                    eprintln!("Warning: Failed to preload module: {e}");
                }
            }
        }

        // Runtime 已通过 worker 管理，只需保留 id
        std::mem::forget(runtime);

        Self { runtime_id: id }
    }

    /// 执行 JavaScript 代码，返回类型化的 [JsValue]。
    ///
    /// 实际执行在工作线程中进行，返回 Future，不阻塞 Dart 主 isolate。
    /// 自动解析顶层 Promise。
    pub fn eval(&self, code: String) -> Result<JsValue, JsError> {
        worker::eval(self.runtime_id, code, JsEvalOptions::default())
    }

    /// 执行 JavaScript 代码，**不**自动 resolve 顶层 Promise。
    ///
    /// 适用于 JS 代码中包含 `await registeredMethod()` 的场景，
    /// 避免 `await_blocking` 与回调等待形成死锁。
    /// 调用后需配合 [run_jobs](Self::run_jobs) 执行微任务。
    pub fn eval_raw(&self, code: String) -> Result<JsValue, JsError> {
        worker::eval_raw(self.runtime_id, code)
    }

    /// 带选项执行 JavaScript 代码。
    pub fn eval_with_options(
        &self,
        code: String,
        options: JsEvalOptions,
    ) -> Result<JsValue, JsError> {
        worker::eval(self.runtime_id, code, options)
    }

    /// 从文件路径读取 JS 代码并执行（Script 模式）。
    pub fn eval_file(
        &self,
        path: String,
        options: Option<JsEvalOptions>,
    ) -> Result<JsValue, JsError> {
        worker::eval_file(self.runtime_id, path, options.unwrap_or_default())
    }

    /// 从字节数组执行 JS 代码（UTF-8 编码）。
    pub fn eval_bytes(
        &self,
        bytes: Vec<u8>,
        options: Option<JsEvalOptions>,
    ) -> Result<JsValue, JsError> {
        worker::eval_bytes(self.runtime_id, bytes, options.unwrap_or_default())
    }

    /// 读取文件作为 ES 模块执行（支持相对路径 import）。
    ///
    /// 文件所在目录设置为模块解析基础路径。
    pub fn eval_path(
        &self,
        path: String,
        options: Option<JsEvalOptions>,
    ) -> Result<JsValue, JsError> {
        worker::eval_path(self.runtime_id, path, options.unwrap_or_default())
    }

    /// 调用已注册模块的导出函数。
    ///
    /// # 参数
    /// - `module`: 模块名称（已通过 [declare_module](Self::declare_module) 注册）
    /// - `method`: 导出函数名
    /// - `params`: 参数列表
    pub fn call(
        &self,
        module: String,
        method: String,
        params: Vec<JsValue>,
    ) -> Result<JsValue, JsError> {
        worker::call_module(self.runtime_id, module, method, params)
    }

    /// 注册一个 ES 模块。
    #[frb(sync)]
    pub fn declare_module(&self, module: JsModule) -> Result<(), JsError> {
        worker::preload_module(self.runtime_id, module.name, module.source)
    }

    /// 批量注册 ES 模块。同一批中的模块名不允许重复。
    #[frb(sync)]
    pub fn declare_modules(&self, modules: Vec<JsModule>) -> Result<(), JsError> {
        worker::declare_modules(self.runtime_id, modules)
    }

    // ─── JS↔Dart 方法调用 ───────────────────────────────

    /// 注册一个全局可构造函数（JS 端可通过 `await <name>(...args)` 或 `new <name>(...args)` 调用）。
    #[frb(sync)]
    pub fn register_global_callable(&self, name: String) -> Result<(), JsError> {
        worker::register_global_callable(self.runtime_id, name)
    }

    /// 注册一个全局纯函数（不可构造，JS 端通过 `await <name>(...args)` 调用）。
    #[frb(sync)]
    pub fn register_global_function(&self, name: String) -> Result<(), JsError> {
        worker::register_global_function(self.runtime_id, name)
    }

    /// 拉取所有来自 JS 的待处理方法调用（排空队列）。
    #[frb(sync)]
    pub fn poll_calls(&self) -> Vec<CompletedCall> {
        worker::poll_calls(self.runtime_id)
            .unwrap_or_default()
            .into_iter()
            .map(|c| CompletedCall {
                call_id: c.call_id,
                name: c.name,
                params: c.params,
            })
            .collect()
    }

    /// 回传成功结果给 JS 端（resolve 对应的 Promise）。
    #[frb(sync)]
    pub fn resolve_call(&self, call_id: u64, result: JsValue) -> Result<(), JsError> {
        worker::resolve_call(self.runtime_id, call_id, result)
    }

    /// 回传错误给 JS 端（reject 对应的 Promise）。
    #[frb(sync)]
    pub fn reject_call(&self, call_id: u64, error: String) -> Result<(), JsError> {
        worker::reject_call(self.runtime_id, call_id, error)
    }

    // ─── 同步回调桥（独立于 worker channel）─────────────

    /// 拉取所有来自 JS 的**同步**调用请求（排空队列）。
    ///
    /// 返回 `(call_id, method_name, args_json)` 列表。
    /// 处理完后用 [resolve_sync_call] / [reject_sync_call] 回传结果。
    ///
    /// 此方法直接访问全局 sync_bridge，不经过 worker channel，
    /// 因此可在 JS 执行期间**实时**被调用。
    #[frb(sync)]
    pub fn poll_sync_calls(&self) -> Vec<SyncCall> {
        crate::js_runtime::sync_bridge::poll_pending_calls()
            .into_iter()
            .map(|(call_id, name, args_json)| SyncCall {
                call_id,
                name,
                args_json,
            })
            .collect()
    }

    /// 回传成功结果给阻塞的 worker 线程（通过 sync_bridge）。
    ///
    /// [result_json] 是 Dart handler 返回值的 JSON 序列化字符串。
    #[frb(sync)]
    pub fn resolve_sync_call(&self, call_id: u64, result_json: String) {
        crate::js_runtime::sync_bridge::resolve_call(call_id, result_json);
    }

    /// 回传错误给阻塞的 worker 线程（通过 sync_bridge）。
    #[frb(sync)]
    pub fn reject_sync_call(&self, call_id: u64, error: String) {
        crate::js_runtime::sync_bridge::reject_call(call_id, error);
    }

    // ─── 同步 FFI 回调（已弃用）──────────────────────────

    /// （内部）注册 Dart 侧 FFI 回调函数指针。
    ///
    /// 直接操作全局 DART_HANDLERS 注册表，无需经过 worker。
    #[frb(sync)]
    pub fn register_dart_handler(&self, ptr: i64) -> Result<(), JsError> {
        internal::register_dart_handler(self.runtime_id, ptr);
        Ok(())
    }

    /// 注册一个同步全局函数（JS 调用立刻响应，无 Promise）。
    #[frb(sync)]
    pub fn register_sync_function(&self, name: String) -> Result<(), JsError> {
        worker::register_sync_function(self.runtime_id, name)
    }

    // ─── 内存管理 ────────────────────────────────────────
    #[frb(sync)]
    pub fn memory_usage(&self) -> u64 {
        worker::memory_usage(self.runtime_id).unwrap_or(0)
    }

    /// 触发垃圾回收。
    #[frb(sync)]
    pub fn run_gc(&self) {
        worker::run_gc(self.runtime_id);
    }

    /// 执行待处理的微任务（Promise reactions）。
    #[frb(sync)]
    pub fn run_jobs(&self) {
        worker::run_jobs(self.runtime_id);
    }

    /// 设置内存上限（字节），`0` 表示不限制。
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64) {
        worker::set_memory_limit(self.runtime_id, limit_bytes);
    }

    /// 关闭引擎，释放所有资源（含已注册的回调函数和待处理调用）。
    #[frb(sync)]
    pub fn close(self) -> Result<(), JsError> {
        internal::unregister_dart_handler(self.runtime_id);
        worker::dispose(self.runtime_id)
    }
}

/// JS→Dart 方法调用请求。
pub struct CompletedCall {
    pub call_id: u64,
    pub name: String,
    pub params: Vec<JsValue>,
}

/// JS→Dart 同步调用请求（sync_bridge 模式）。
///
/// 通过 `poll_sync_calls` 获取，处理完后用 `resolve_sync_call` 回传。
pub struct SyncCall {
    pub call_id: u64,
    pub name: String,
    /// JSON 序列化的参数数组
    pub args_json: String,
}

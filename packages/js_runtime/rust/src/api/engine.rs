//! JsEngine —— 高层 JS 引擎 API。
//!
//! 参考 FJS 的 `JsEngine` 设计，封装运行时生命周期，
//! 提供更简洁的 API 供日常使用。
//!
//! 低层 API 见 [super::runtime::JsRuntime]。

use boa_engine::js_string;
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

    /// 执行 JavaScript 代码，**不**自动 resolve 顶层 Promise。
    ///
    /// 适用于 JS 代码中包含 `await registeredMethod()` 的场景，
    /// 避免 `await_blocking` 与回调等待形成死锁。
    /// 调用后需配合 [run_jobs](Self::run_jobs) 执行微任务。
    #[frb(sync)]
    pub fn eval_raw(&self, code: String) -> Result<JsValue, JsError> {
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.runtime_id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Engine runtime {} not found", self.runtime_id),
                })?;

            let result = state
                .context
                .eval(boa_engine::Source::from_bytes(code.as_bytes()))
                .map_err(JsError::from)?;

            Ok(JsValue::from_boa(&result, &mut state.context))
        })
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

    // ─── JS↔Dart 方法调用 ───────────────────────────────

    /// 注册一个全局可构造函数（JS 端可通过 `await <name>(...args)` 或 `new <name>(...args)` 调用）。
    ///
    /// 内部使用 Boa 的 `context.register_global_callable()`，
    /// 创建的函数既是 callable 又是 constructable。
    ///
    /// JS 调用返回 Promise，Dart 通过 [poll_calls](Self::poll_calls) 获取调用请求，
    /// 处理完后用 [resolve_call](Self::resolve_call) 或 [reject_call](Self::reject_call) 回传结果。
    ///
    /// # 示例
    ///
    /// ```dart
    /// engine.registerGlobalCallable(name: 'sum');
    /// engine.eval(code: 'sum(3, 4).then(r => console.log(r));');
    /// final calls = engine.pollCalls();
    /// engine.resolveCall(callId: calls.first.callId, result: JsValue.integer(7));
    /// engine.runJobs();
    /// ```
    #[frb(sync)]
    pub fn register_global_callable(&self, name: String) -> Result<(), JsError> {
        let native_fn = internal::create_native_fn(name.clone());
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.runtime_id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Engine runtime {} not found", self.runtime_id),
                })?;

            state
                .context
                .register_global_callable(
                    js_string!(name.clone()),
                    name.len(),
                    native_fn,
                )
                .map_err(|e| JsError::Internal {
                    message: format!("Failed to register global callable '{name}': {e}"),
                })
        })
    }

    /// 注册一个全局纯函数（不可构造，JS 端通过 `await <name>(...args)` 调用）。
    ///
    /// 内部使用 `FunctionObjectBuilder` 构建不可构造的函数对象，
    /// 并手动绑定到全局对象。`new <name>(...)` 会抛出 TypeError。
    ///
    /// JS 调用返回 Promise，与 [register_global_callable](Self::register_global_callable)
    /// 共用相同的 poll/resolve 机制。
    #[frb(sync)]
    pub fn register_global_function(&self, name: String) -> Result<(), JsError> {
        let native_fn = internal::create_native_fn(name.clone());
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.runtime_id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Engine runtime {} not found", self.runtime_id),
                })?;

            use boa_engine::object::FunctionObjectBuilder;
            use boa_engine::property::PropertyDescriptor;

            let function = FunctionObjectBuilder::new(state.context.realm(), native_fn)
                .name(js_string!(name.clone()))
                .length(name.len())
                .constructor(false)
                .build();

            state
                .context
                .global_object()
                .define_property_or_throw(
                    js_string!(name.clone()),
                    PropertyDescriptor::builder()
                        .value(function)
                        .writable(true)
                        .enumerable(false)
                        .configurable(true),
                    &mut state.context,
                )
                .map(|_| ())
                .map_err(|e| JsError::Internal {
                    message: format!("Failed to register global function '{name}': {e}"),
                })
        })
    }

    /// 拉取所有来自 JS 的待处理方法调用（排空队列）。
    ///
    /// 返回 [CompletedCall] 列表。每个调用需通过 [resolve_call](Self::resolve_call)
    /// 或 [reject_call](Self::reject_call) 回传结果。
    #[frb(sync)]
    pub fn poll_calls(&self) -> Vec<CompletedCall> {
        internal::COMPLETED_CALLS.with(|list| {
            std::mem::take(&mut *list.borrow_mut())
                .into_iter()
                .map(|c| CompletedCall {
                    call_id: c.call_id,
                    name: c.name,
                    params: c.params,
                })
                .collect()
        })
    }

    /// 回传成功结果给 JS 端（resolve 对应的 Promise）。
    ///
    /// 调用后应执行 [run_jobs](Self::run_jobs) 让 JS 侧的 `.then()` 回调运行。
    #[frb(sync)]
    pub fn resolve_call(&self, call_id: u64, result: JsValue) -> Result<(), JsError> {
        internal::PENDING_CALLS.with(|map| {
            if let Some(pending) = map.borrow_mut().remove(&call_id) {
                internal::RUNTIMES.with(|runtimes| {
                    let mut runtimes = runtimes.borrow_mut();
                    let state =
                        runtimes
                            .get_mut(&self.runtime_id)
                            .ok_or_else(|| JsError::Internal {
                                message: format!(
                                    "Engine runtime {} not found",
                                    self.runtime_id
                                ),
                            })?;

                    let boa_val = result
                        .to_boa(&mut state.context)
                        .map_err(|e| JsError::Internal {
                            message: format!("Failed to convert result: {e}"),
                        })?;
                    pending
                        .resolvers
                        .resolve
                        .call(
                            &boa_engine::JsValue::undefined(),
                            &[boa_val],
                            &mut state.context,
                        )
                        .map_err(|e| JsError::Internal {
                            message: format!("Failed to resolve promise: {e}"),
                        })?;
                    Ok(())
                })
            } else {
                Ok(()) // 调用已超时或不存在，静默忽略
            }
        })
    }

    /// 回传错误给 JS 端（reject 对应的 Promise）。
    ///
    /// 调用后应执行 [run_jobs](Self::run_jobs) 让 JS 侧的 `.catch()` 回调运行。
    #[frb(sync)]
    pub fn reject_call(&self, call_id: u64, error: String) -> Result<(), JsError> {
        internal::PENDING_CALLS.with(|map| {
            if let Some(pending) = map.borrow_mut().remove(&call_id) {
                internal::RUNTIMES.with(|runtimes| {
                    let mut runtimes = runtimes.borrow_mut();
                    let state =
                        runtimes
                            .get_mut(&self.runtime_id)
                            .ok_or_else(|| JsError::Internal {
                                message: format!(
                                    "Engine runtime {} not found",
                                    self.runtime_id
                                ),
                            })?;

                    let err = boa_engine::JsError::from_native(
                        boa_engine::JsNativeError::typ().with_message(error),
                    );
                    pending
                        .resolvers
                        .reject
                        .call(
                            &boa_engine::JsValue::undefined(),
                            &[err.to_opaque(&mut state.context)],
                            &mut state.context,
                        )
                        .map_err(|e| JsError::Internal {
                            message: format!("Failed to reject promise: {e}"),
                        })?;
                    Ok(())
                })
            } else {
                Ok(()) // 调用已超时或不存在，静默忽略
            }
        })
    }

    // ─── 同步 FFI 回调 ──────────────────────────────────

    /// （内部）注册 Dart 侧 FFI 回调函数指针。
    ///
    /// 由 [JsCallbackHandler] 在构造时调用，传入 `NativeCallable.nativeFunction.address`。
    /// 所有通过 [register_sync_function](Self::register_sync_function) 注册的方法
    /// 共享这同一个函数指针（通过 JSON 中的方法名分发）。
    #[frb(sync)]
    pub fn register_dart_handler(&self, ptr: i64) -> Result<(), JsError> {
        internal::register_dart_handler(self.runtime_id, ptr);
        Ok(())
    }

    /// 注册一个同步全局函数（JS 调用立刻响应，无 Promise）。
    ///
    /// 内部使用 `create_sync_native_fn` 创建 NativeFunction，
    /// 通过 FFI 直接同步调用 Dart handler，返回结果给 JS。
    ///
    /// JS 端可 **直接拿到返回值**：`const x = sum(3, 4)`（无需 `await`）。
    ///
    /// 使用 `FunctionObjectBuilder` 构建不可构造的纯函数。
    /// 如需可构造版本，使用 [register_global_callable](Self::register_global_callable)。
    ///
    /// # 前提
    /// 需先通过 [register_dart_handler](Self::register_dart_handler) 注册 Dart 回调指针
    /// （由 [JsCallbackHandler] 自动处理）。
    #[frb(sync)]
    pub fn register_sync_function(&self, name: String) -> Result<(), JsError> {
        let native_fn = internal::create_sync_native_fn(name.clone(), self.runtime_id);
        internal::RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.runtime_id)
                .ok_or_else(|| JsError::Internal {
                    message: format!("Engine runtime {} not found", self.runtime_id),
                })?;

            use boa_engine::object::FunctionObjectBuilder;
            use boa_engine::property::PropertyDescriptor;

            let function = FunctionObjectBuilder::new(state.context.realm(), native_fn)
                .name(js_string!(name.clone()))
                .length(name.len())
                .constructor(false)
                .build();

            state
                .context
                .global_object()
                .define_property_or_throw(
                    js_string!(name.clone()),
                    PropertyDescriptor::builder()
                        .value(function)
                        .writable(true)
                        .enumerable(false)
                        .configurable(true),
                    &mut state.context,
                )
                .map(|_| ())
                .map_err(|e| JsError::Internal {
                    message: format!("Failed to register sync function '{name}': {e}"),
                })
        })
    }

    // ─── 内存管理 ────────────────────────────────────────
    #[frb(sync)]
    pub fn memory_usage(&self) -> u64 {
        self.runtime().memory_usage()
    }

    /// 触发垃圾回收。
    #[frb(sync)]
    pub fn run_gc(&self) {
        self.runtime().run_gc();
    }

    /// 执行待处理的微任务（Promise reactions）。
    ///
    /// 在 `resolve_call` 或 `reject_call` 之后调用，确保 JS 侧的
    /// `.then()` / `.catch()` 回调被执行。
    #[frb(sync)]
    pub fn run_jobs(&self) {
        internal::RUNTIMES.with(|map| {
            if let Some(state) = map.borrow_mut().get_mut(&self.runtime_id) {
                state.context.run_jobs();
            }
        });
    }

    /// 设置内存上限（字节），`0` 表示不限制。
    #[frb(sync)]
    pub fn set_memory_limit(&self, limit_bytes: u64) {
        self.runtime().set_memory_limit(limit_bytes);
    }

    /// 关闭引擎，释放所有资源（含已注册的回调函数和待处理调用）。
    #[frb(sync)]
    pub fn close(self) -> Result<(), JsError> {
        // 清理 Dart handler
        internal::unregister_dart_handler(self.runtime_id);
        // 清理待处理方法调用
        internal::PENDING_CALLS.with(|map| {
            map.borrow_mut().clear();
        });
        internal::COMPLETED_CALLS.with(|list| {
            list.borrow_mut().clear();
        });

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

/// JS→Dart 方法调用请求。
///
/// 通过 [JsEngine::poll_calls] 获取，处理完后调用 [JsEngine::resolve_call]
/// 或 [JsEngine::reject_call] 回传结果。
pub struct CompletedCall {
    /// 调用唯一 ID（用于 `resolve_call` / `reject_call` 回传结果）
    pub call_id: u64,
    /// 注册的方法名
    pub name: String,
    /// 调用参数
    pub params: Vec<JsValue>,
}

//! JS 运行时工作线程。
//!
//! 每个 JsRuntime 拥有一个专用 OS 线程（worker），线程内持有 Boa Context。
//! 所有操作通过 mpsc channel 发送命令，在工作线程中执行，
//! 结果通过 mpsc channel 返回。
//!
//! 此模块不在 `crate::api` 路径下，不会被 flutter_rust_bridge 扫描。

use std::collections::HashMap;
use std::sync::mpsc;
use std::sync::Mutex;
use std::thread;

use boa_engine::Context;
use boa_engine::Source;

use crate::api::eval_options::JsEvalOptions;
use crate::api::js_error::JsError;
use crate::api::js_value::JsValue;
use crate::js_runtime::internal::{self, RuntimeState};

/// 工作线程命令。
pub(crate) enum WorkerCmd {
    /// 执行 JS 代码字符串
    Eval {
        code: String,
        options: JsEvalOptions,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 执行 JS 代码（不自动 resolve Promise）
    EvalRaw {
        code: String,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 读取文件并执行 JS
    EvalFile {
        path: String,
        options: JsEvalOptions,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 从字节数组执行 JS（UTF-8）
    EvalBytes {
        bytes: Vec<u8>,
        options: JsEvalOptions,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 读取文件作为 ES 模块执行（支持相对 import）
    EvalPath {
        path: String,
        options: JsEvalOptions,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 预加载 ES 模块
    PreloadModule {
        name: String,
        source: String,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 调用已注册模块的导出函数
    Call {
        module: String,
        method: String,
        params: Vec<JsValue>,
        reply: mpsc::Sender<Result<JsValue, JsError>>,
    },
    /// 注册全局可构造函数（含 Promise 回调）
    RegisterGlobalCallable {
        name: String,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 注册全局纯函数（含 Promise 回调）
    RegisterGlobalFunction {
        name: String,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 注册同步函数（FFI 直接回调，无 Promise）
    RegisterSyncFunction {
        name: String,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 拉取待处理的 JS→Dart 调用
    PollCalls {
        reply: mpsc::Sender<Vec<internal::CompletedCall>>,
    },
    /// 回传成功结果给 JS
    ResolveCall {
        call_id: u64,
        result: JsValue,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 回传错误给 JS
    RejectCall {
        call_id: u64,
        error: String,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 执行微任务队列
    RunJobs,
    /// 触发 GC
    RunGc,
    /// 获取内存用量
    MemoryUsage {
        reply: mpsc::Sender<u64>,
    },
    /// 设置内存上限
    SetMemoryLimit {
        limit_bytes: u64,
    },
    /// REPL 专用 eval：返回 (字符串表示, 结构化值)
    ReplEval {
        code: String,
        reply: mpsc::Sender<Result<(String, JsValue), JsError>>,
    },
    /// 旧版字符串 eval
    EvalJsStr {
        code: String,
        reply: mpsc::Sender<Result<String, String>>,
    },
    /// 批量注册模块
    DeclareModules {
        modules: Vec<crate::api::module::JsModule>,
        reply: mpsc::Sender<Result<(), JsError>>,
    },
    /// 销毁运行时
    Dispose {
        reply: mpsc::Sender<Result<(), JsError>>,
    },
}

/// 工作线程句柄。
pub(crate) struct WorkerHandle {
    pub sender: mpsc::Sender<WorkerCmd>,
    pub thread: Option<thread::JoinHandle<()>>,
}

/// 全局工作线程注册表。
pub(crate) static WORKERS: std::sync::LazyLock<Mutex<HashMap<u64, WorkerHandle>>> =
    std::sync::LazyLock::new(|| Mutex::new(HashMap::new()));

// ─── 公开 API（供 runtime.rs / engine.rs 调用）────────────

/// 发送命令并等待带 Result 包装的回复。
/// T 是成功值类型，worker 通过 `mpsc::Sender<Result<T, JsError>>` 回复。
/// 返回 `Result<T, JsError>`（已展平两层 Result）。
fn send_and_wait<T>(
    runtime_id: u64,
    make_cmd: impl FnOnce(mpsc::Sender<Result<T, JsError>>) -> WorkerCmd,
) -> Result<T, JsError> {
    let (tx, rx) = mpsc::channel();
    {
        let map = WORKERS
            .lock()
            .map_err(|e| JsError::Internal {
                message: format!("WORKERS lock poisoned: {e}"),
            })?;
        let handle = map
            .get(&runtime_id)
            .ok_or_else(|| JsError::Internal {
                message: format!("Runtime {runtime_id} not found"),
            })?;
        if handle.sender.send(make_cmd(tx)).is_err() {
            return Err(JsError::Internal {
                message: "Worker thread disconnected".into(),
            });
        }
    }
    match rx.recv() {
        Ok(Ok(value)) => Ok(value),
        Ok(Err(e)) => Err(e),
        Err(_) => Err(JsError::Internal {
            message: "Worker thread disconnected".into(),
        }),
    }
}

/// 发送命令并等待原始值回复（worker 不包装 Result，如 u64、Vec<T>）。
fn send_and_wait_raw<T>(
    runtime_id: u64,
    make_cmd: impl FnOnce(mpsc::Sender<T>) -> WorkerCmd,
) -> Result<T, JsError> {
    let (tx, rx) = mpsc::channel();
    {
        let map = WORKERS
            .lock()
            .map_err(|e| JsError::Internal {
                message: format!("WORKERS lock poisoned: {e}"),
            })?;
        let handle = map
            .get(&runtime_id)
            .ok_or_else(|| JsError::Internal {
                message: format!("Runtime {runtime_id} not found"),
            })?;
        if handle.sender.send(make_cmd(tx)).is_err() {
            return Err(JsError::Internal {
                message: "Worker thread disconnected".into(),
            });
        }
    }
    rx.recv().map_err(|_| JsError::Internal {
        message: "Worker thread disconnected".into(),
    })
}

/// 发送命令并等待带 `Result<String, String>` 回复（eval_js_str 专用）。
fn send_and_wait_str<T>(
    runtime_id: u64,
    make_cmd: impl FnOnce(mpsc::Sender<Result<T, String>>) -> WorkerCmd,
) -> Result<T, String> {
    let (tx, rx) = mpsc::channel();
    {
        let map = WORKERS.lock().map_err(|e| format!("WORKERS lock poisoned: {e}"))?;
        let handle = map
            .get(&runtime_id)
            .ok_or_else(|| format!("Runtime {runtime_id} not found"))?;
        if handle.sender.send(make_cmd(tx)).is_err() {
            return Err("Worker thread disconnected".to_string());
        }
    }
    match rx.recv() {
        Ok(Ok(value)) => Ok(value),
        Ok(Err(e)) => Err(e),
        Err(_) => Err("Worker thread disconnected".to_string()),
    }
}

fn send_without_reply(runtime_id: u64, cmd: WorkerCmd) -> Result<(), JsError> {
    let map = WORKERS
        .lock()
        .map_err(|e| JsError::Internal {
            message: format!("WORKERS lock poisoned: {e}"),
        })?;
    let handle = map
        .get(&runtime_id)
        .ok_or_else(|| JsError::Internal {
            message: format!("Runtime {runtime_id} not found"),
        })?;
    handle.sender.send(cmd).map_err(|e| JsError::Internal {
        message: format!("Worker thread disconnected: {e}"),
    })
}

pub(crate) fn eval(runtime_id: u64, code: String, options: JsEvalOptions) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::Eval { code, options, reply: tx })
}

pub(crate) fn eval_raw(runtime_id: u64, code: String) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::EvalRaw { code, reply: tx })
}

pub(crate) fn eval_file(runtime_id: u64, path: String, options: JsEvalOptions) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::EvalFile { path, options, reply: tx })
}

pub(crate) fn eval_bytes(runtime_id: u64, bytes: Vec<u8>, options: JsEvalOptions) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::EvalBytes { bytes, options, reply: tx })
}

pub(crate) fn eval_path(runtime_id: u64, path: String, options: JsEvalOptions) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::EvalPath { path, options, reply: tx })
}

pub(crate) fn preload_module(runtime_id: u64, name: String, source: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::PreloadModule { name, source, reply: tx })
}

pub(crate) fn call_module(runtime_id: u64, module: String, method: String, params: Vec<JsValue>) -> Result<JsValue, JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::Call { module, method, params, reply: tx })
}

pub(crate) fn register_global_callable(runtime_id: u64, name: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::RegisterGlobalCallable { name, reply: tx })
}

pub(crate) fn register_global_function(runtime_id: u64, name: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::RegisterGlobalFunction { name, reply: tx })
}

pub(crate) fn register_sync_function(runtime_id: u64, name: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::RegisterSyncFunction { name, reply: tx })
}

pub(crate) fn poll_calls(runtime_id: u64) -> Result<Vec<internal::CompletedCall>, JsError> {
    send_and_wait_raw(runtime_id, |tx| WorkerCmd::PollCalls { reply: tx })
}

pub(crate) fn resolve_call(runtime_id: u64, call_id: u64, result: JsValue) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::ResolveCall { call_id, result, reply: tx })
}

pub(crate) fn reject_call(runtime_id: u64, call_id: u64, error: String) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::RejectCall { call_id, error, reply: tx })
}

pub(crate) fn run_jobs(runtime_id: u64) {
    let _ = send_without_reply(runtime_id, WorkerCmd::RunJobs);
}

pub(crate) fn run_gc(runtime_id: u64) {
    let _ = send_without_reply(runtime_id, WorkerCmd::RunGc);
}

pub(crate) fn memory_usage(runtime_id: u64) -> Result<u64, JsError> {
    send_and_wait_raw(runtime_id, |tx| WorkerCmd::MemoryUsage { reply: tx })
}

pub(crate) fn set_memory_limit(runtime_id: u64, limit_bytes: u64) {
    let _ = send_without_reply(runtime_id, WorkerCmd::SetMemoryLimit { limit_bytes });
}

pub(crate) fn eval_js_str(runtime_id: u64, code: String) -> Result<String, String> {
    send_and_wait_str(runtime_id, |tx| WorkerCmd::EvalJsStr { code, reply: tx })
}

pub(crate) fn declare_modules(runtime_id: u64, modules: Vec<crate::api::module::JsModule>) -> Result<(), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::DeclareModules { modules, reply: tx })
}

pub(crate) fn dispose(runtime_id: u64) -> Result<(), JsError> {
    let result = send_and_wait(runtime_id, |tx| WorkerCmd::Dispose { reply: tx });

    let handle = {
        let mut map = WORKERS.lock().map_err(|e| JsError::Internal {
            message: format!("WORKERS lock poisoned: {e}"),
        })?;
        map.remove(&runtime_id)
    };

    if let Some(mut h) = handle {
        drop(h.sender);
        if let Some(thread) = h.thread.take() {
            let _ = thread.join();
        }
    }

    result
}

// ─── 工作线程启动 ──────────────────────────────────────────

pub(crate) fn spawn_worker(
    max_memory: u64,
    runtime_id: u64,
    _builtins: Option<crate::api::builtin_options::JsBuiltinOptions>,
) -> Result<(), String> {
    let (tx, rx) = mpsc::channel::<WorkerCmd>();

    let handle = thread::Builder::new()
        .name(format!("js-runtime-{runtime_id}"))
        .spawn(move || {
            worker_loop(rx, max_memory, runtime_id);
        })
        .map_err(|e| format!("Failed to spawn worker thread: {e}"))?;

    WORKERS
        .lock()
        .map_err(|e| format!("WORKERS lock poisoned: {e}"))?
        .insert(
            runtime_id,
            WorkerHandle {
                sender: tx,
                thread: Some(handle),
            },
        );

    Ok(())
}

// ─── 工作线程主循环 ────────────────────────────────────────

fn worker_loop(rx: mpsc::Receiver<WorkerCmd>, max_memory: u64, runtime_id: u64) {
    let mut state = match internal::init_context(max_memory, runtime_id) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("[js-runtime-{runtime_id}] Failed to init context: {e}");
            return;
        }
    };

    while let Ok(cmd) = rx.recv() {
        match cmd {
            WorkerCmd::Eval { code, options, reply } => {
                let result = eval_in_context(&mut state, &code, &options);
                let _ = reply.send(result);
            }
            WorkerCmd::EvalRaw { code, reply } => {
                let result = eval_raw_in_context(&mut state, &code);
                let _ = reply.send(result);
            }
            WorkerCmd::EvalFile { path, options, reply } => {
                let result = (|| {
                    let code = std::fs::read_to_string(&path).map_err(|e| JsError::Internal {
                        message: format!("Cannot read file '{path}': {e}"),
                    })?;
                    eval_in_context(&mut state, &code, &options)
                })();
                let _ = reply.send(result);
            }
            WorkerCmd::EvalBytes { bytes, options, reply } => {
                let result = (|| {
                    let code = String::from_utf8(bytes).map_err(|e| JsError::Internal {
                        message: format!("Invalid UTF-8: {e}"),
                    })?;
                    eval_in_context(&mut state, &code, &options)
                })();
                let _ = reply.send(result);
            }
            WorkerCmd::EvalPath { path, options, reply } => {
                let result = (|| {
                    let code = std::fs::read_to_string(&path).map_err(|e| JsError::Internal {
                        message: format!("Cannot read file '{path}': {e}"),
                    })?;
                    // 将文件所在目录设置为环境变量，供模块解析使用
                    if let Some(parent) = std::path::Path::new(&path).parent() {
                        let dir = parent.to_string_lossy();
                        std::env::set_var("JS_MODULE_BASE_PATH", dir.as_ref());
                    }
                    eval_in_context(&mut state, &code, &options)
                })();
                let _ = reply.send(result);
            }
            WorkerCmd::PreloadModule { name, source, reply } => {
                let result = preload_module_inner(&mut state, &name, &source);
                let _ = reply.send(result);
            }
            WorkerCmd::Call { module, method, params, reply } => {
                let result = call_module_inner(&mut state, &module, &method, &params);
                let _ = reply.send(result);
            }
            WorkerCmd::RegisterGlobalCallable { name, reply } => {
                let result = register_global_callable_inner(&mut state.context, &name);
                let _ = reply.send(result);
            }
            WorkerCmd::RegisterGlobalFunction { name, reply } => {
                let result = register_global_function_inner(&mut state.context, &name);
                let _ = reply.send(result);
            }
            WorkerCmd::RegisterSyncFunction { name, reply } => {
                let result = register_sync_function_inner(&mut state.context, &name, runtime_id);
                let _ = reply.send(result);
            }
            WorkerCmd::PollCalls { reply } => {
                let calls: Vec<internal::CompletedCall> = internal::worker_locals::COMPLETED_CALLS
                    .with(|list| std::mem::take(&mut *list.borrow_mut()));
                let _ = reply.send(calls);
            }
            WorkerCmd::ResolveCall { call_id, result, reply } => {
                let res = internal::worker_locals::PENDING_CALLS.with(|map| {
                    if let Some(pending) = map.borrow_mut().remove(&call_id) {
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
                    }
                    Ok(())
                });
                let _ = reply.send(res);
            }
            WorkerCmd::RejectCall { call_id, error, reply } => {
                let res = internal::worker_locals::PENDING_CALLS.with(|map| {
                    if let Some(pending) = map.borrow_mut().remove(&call_id) {
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
                    }
                    Ok(())
                });
                let _ = reply.send(res);
            }
            WorkerCmd::RunJobs => {
                let _ = state.context.run_jobs();
            }
            WorkerCmd::RunGc => {
                boa_gc::force_collect();
                state.context.clear_kept_objects();
                state.estimated_memory = state.total_module_bytes;
                state.total_code_bytes = 0;
            }
            WorkerCmd::MemoryUsage { reply } => {
                let _ = reply.send(state.estimated_memory);
            }
            WorkerCmd::SetMemoryLimit { limit_bytes } => {
                state.max_memory = limit_bytes;
            }
            WorkerCmd::ReplEval { code, reply } => {
                let result = repl_eval_in_context(&mut state, &code);
                let _ = reply.send(result);
            }
            WorkerCmd::EvalJsStr { code, reply } => {
                let result = internal::eval_and_resolve(&code, &mut state);
                if result.is_ok() {
                    let code_bytes = code.len() as u64;
                    state.total_code_bytes += code_bytes;
                    state.estimated_memory += code_bytes;
                }
                let _ = reply.send(result);
            }
            WorkerCmd::DeclareModules { modules, reply } => {
                let mut result = Ok(());
                for m in modules {
                    if let Err(e) = preload_module_inner(&mut state, &m.name, &m.source) {
                        result = Err(e);
                        break;
                    }
                }
                let _ = reply.send(result);
            }
            WorkerCmd::Dispose { reply } => {
                let _ = reply.send(Ok(()));
                break;
            }
        }
    }

    // 清理线程局部回调队列
    internal::worker_locals::COMPLETED_CALLS.with(|list| list.borrow_mut().clear());
    internal::worker_locals::PENDING_CALLS.with(|map| map.borrow_mut().clear());
}

// ─── 内部实现辅助函数 ──────────────────────────────────────

fn eval_in_context(
    state: &mut RuntimeState,
    code: &str,
    options: &JsEvalOptions,
) -> Result<JsValue, JsError> {
    internal::check_memory_limit(state)
        .map_err(|msg| JsError::MemoryLimit { message: msg })?;

    let source = options.apply(code);

    let result = match state.context.eval(Source::from_bytes(source.as_bytes())) {
        Ok(value) => {
            let resolved = if let Some(promise) = value.as_promise() {
                match promise.await_blocking(&mut state.context) {
                    Ok(v) => v,
                    Err(e) => return Err(JsError::from(e)),
                }
            } else {
                value
            };
            JsValue::from_boa(&resolved, &mut state.context)
        }
        Err(e) => return Err(JsError::from(e)),
    };

    let code_bytes = code.len() as u64;
    state.total_code_bytes += code_bytes;
    state.estimated_memory += code_bytes;

    internal::check_memory_limit(state)
        .map_err(|msg| JsError::MemoryLimit { message: msg })?;

    Ok(result)
}

fn eval_raw_in_context(state: &mut RuntimeState, code: &str) -> Result<JsValue, JsError> {
    let result = state
        .context
        .eval(Source::from_bytes(code.as_bytes()))
        .map_err(JsError::from)?;

    Ok(JsValue::from_boa(&result, &mut state.context))
}

fn preload_module_inner(
    state: &mut RuntimeState,
    name: &str,
    source: &str,
) -> Result<(), JsError> {
    let module = internal::parse_module(name, source, &mut state.context)
        .map_err(|e| JsError::Internal { message: e })?;

    let loader = internal::get_module_loader(&mut state.context)
        .map_err(|e| JsError::Internal { message: e })?;

    loader.insert(name, module);

    let bytes = source.len() as u64;
    state.total_module_bytes += bytes;
    state.estimated_memory += bytes;

    Ok(())
}

fn call_module_inner(
    state: &mut RuntimeState,
    module: &str,
    method: &str,
    params: &[JsValue],
) -> Result<JsValue, JsError> {
    use crate::api::js_value::js_value_to_literal;

    let mut args_parts = Vec::with_capacity(params.len());
    for param in params {
        let lit = js_value_to_literal(param, &mut state.context)?;
        args_parts.push(lit);
    }
    let args_code = args_parts.join(", ");

    let code = format!(
        "await import('{module}').then(function(m) {{ return m.{method}({args_code}); }})"
    );

    let result = state
        .context
        .eval(Source::from_bytes(code.as_bytes()))
        .map_err(JsError::from)?;

    let resolved = if let Some(promise) = result.as_promise() {
        promise
            .await_blocking(&mut state.context)
            .map_err(JsError::from)?
    } else {
        result
    };

    Ok(JsValue::from_boa(&resolved, &mut state.context))
}

// ─── 回调注册辅助 ──────────────────────────────────────────

fn register_global_callable_inner(context: &mut Context, name: &str) -> Result<(), JsError> {
    use boa_engine::js_string;

    let native_fn = internal::create_native_fn(name.to_string());

    context
        .register_global_callable(js_string!(name), name.len(), native_fn)
        .map_err(|e| JsError::Internal {
            message: format!("Failed to register global callable '{name}': {e}"),
        })
}

fn register_global_function_inner(context: &mut Context, name: &str) -> Result<(), JsError> {
    use boa_engine::js_string;
    use boa_engine::object::FunctionObjectBuilder;
    use boa_engine::property::PropertyDescriptor;

    let native_fn = internal::create_native_fn(name.to_string());

    let function = FunctionObjectBuilder::new(context.realm(), native_fn)
        .name(js_string!(name))
        .length(name.len())
        .constructor(false)
        .build();

    context
        .global_object()
        .define_property_or_throw(
            js_string!(name),
            PropertyDescriptor::builder()
                .value(function)
                .writable(true)
                .enumerable(false)
                .configurable(true),
            context,
        )
        .map(|_| ())
        .map_err(|e| JsError::Internal {
            message: format!("Failed to register global function '{name}': {e}"),
        })
}

pub(crate) fn repl_eval(
    runtime_id: u64,
    code: String,
) -> Result<(String, JsValue), JsError> {
    send_and_wait(runtime_id, |tx| WorkerCmd::ReplEval { code, reply: tx })
}

fn repl_eval_in_context(
    state: &mut RuntimeState,
    code: &str,
) -> Result<(String, JsValue), JsError> {
    match state.context.eval(Source::from_bytes(code.as_bytes())) {
        Ok(value) => {
            let resolved = if let Some(promise) = value.as_promise() {
                match promise.await_blocking(&mut state.context) {
                    Ok(v) => v,
                    Err(e) => return Err(JsError::from(e)),
                }
            } else {
                value
            };
            let js_val = JsValue::from_boa(&resolved, &mut state.context);
            let output = resolved
                .to_string(&mut state.context)
                .map(|s| s.to_std_string_escaped())
                .unwrap_or_else(|_| "undefined".to_string());
            Ok((output, js_val))
        }
        Err(e) => Err(JsError::from(e)),
    }
}

fn register_sync_function_inner(
    context: &mut Context,
    name: &str,
    runtime_id: u64,
) -> Result<(), JsError> {
    use boa_engine::js_string;
    use boa_engine::object::FunctionObjectBuilder;
    use boa_engine::property::PropertyDescriptor;

    let native_fn = internal::create_sync_native_fn(name.to_string(), runtime_id);

    let function = FunctionObjectBuilder::new(context.realm(), native_fn)
        .name(js_string!(name))
        .length(name.len())
        .constructor(false)
        .build();

    context
        .global_object()
        .define_property_or_throw(
            js_string!(name),
            PropertyDescriptor::builder()
                .value(function)
                .writable(true)
                .enumerable(false)
                .configurable(true),
            context,
        )
        .map(|_| ())
        .map_err(|e| JsError::Internal {
            message: format!("Failed to register sync function '{name}': {e}"),
        })
}

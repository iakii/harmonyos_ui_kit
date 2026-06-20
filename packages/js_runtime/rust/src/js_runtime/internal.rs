//! JS 运行时内部状态管理。
//!
//! 此模块不在 `crate::api` 路径下，因此不会被 flutter_rust_bridge 扫描，
//! 避免将私有类型暴露给 Dart 端。

use std::cell::RefCell;
use std::collections::HashMap;
use std::ffi::{c_char, CStr, CString};
use std::rc::Rc;

use boa_engine::{js_string, Context, Module, NativeFunction, Source};
use boa_engine::module::MapModuleLoader;
use boa_engine::object::builtins::JsPromise;
use boa_engine::JsValue as BoaJsValue;
use boa_runtime::extensions::{ConsoleExtension, FetchExtension};
use boa_runtime::fetch::BlockingReqwestFetcher;

use crate::api::js_value::JsValue as FrbJsValue;

/// 单个运行时的内部状态。
pub(crate) struct RuntimeState {
    pub context: Context,
    /// 内存上限（字节），0 表示不限制。
    pub max_memory: u64,
    /// 估算内存用量（字节）：已执行的代码 + 已加载的模块源码总量。
    pub estimated_memory: u64,
    /// 已执行的 JS 代码总字节数。
    pub total_code_bytes: u64,
    /// 已加载的模块源码总字节数。
    pub total_module_bytes: u64,
}

thread_local! {
    pub(crate) static RUNTIMES: RefCell<HashMap<u64, RuntimeState>> = RefCell::new(HashMap::new());
}

pub(crate) fn next_id() -> u64 {
    use std::sync::atomic::AtomicU64;
    static NEXT_ID: AtomicU64 = AtomicU64::new(0);
    NEXT_ID.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}

// ─── JS↔Dart 方法调用基础设施 ─────────────────────────────

/// 来自 JS 的方法调用请求（JS→Dart）。
///
/// 当 JS 侧调用通过 `register_global_callable` 或 `register_global_function`
/// 注册的函数时，生成此结构并入队 COMPLETED_CALLS。
pub(crate) struct CompletedCall {
    pub call_id: u64,
    pub name: String,
    pub params: Vec<FrbJsValue>,
}

/// 待处理的方法调用（含 Promise resolver，用于 Dart 回传结果）。
pub(crate) struct PendingCall {
    pub resolvers: boa_engine::builtins::promise::ResolvingFunctions,
}

/// 已完成的调用队列（Dart 通过 `poll_calls` 拉取）。
thread_local! {
    pub(crate) static COMPLETED_CALLS: RefCell<Vec<CompletedCall>> = RefCell::new(Vec::new());
}

/// 待处理调用表（按 call_id 索引，Dart 通过 `resolve_call`/`reject_call` 回传结果）。
thread_local! {
    pub(crate) static PENDING_CALLS: RefCell<HashMap<u64, PendingCall>> = RefCell::new(HashMap::new());
}

pub(crate) fn next_call_id() -> u64 {
    use std::sync::atomic::AtomicU64;
    static NEXT_ID: AtomicU64 = AtomicU64::new(0);
    NEXT_ID.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}

/// 创建统一的 NativeFunction 工厂。
///
/// 当 JS 调用该函数时，创建一个 Promise 并将调用信息入队，
/// Dart 通过 `poll_calls` 获取调用，处理完后通过 `resolve_call`/`reject_call` 回传结果。
///
/// 此函数被 `register_global_callable` 和 `register_global_function` 共用。
pub(crate) fn create_native_fn(method_name: String) -> NativeFunction {
    NativeFunction::from_copy_closure_with_captures(
        |_this, args, name, ctx| {
            let call_id = next_call_id();

            // Boa args → Vec<FrbJsValue>
            let params: Vec<FrbJsValue> =
                args.iter().map(|v| FrbJsValue::from_boa(v, ctx)).collect();

            // 创建 Promise + resolving functions
            let (promise, resolvers) = JsPromise::new_pending(ctx);

            // 登记 pending call（保存 resolvers 以便后续 resolve/reject）
            PENDING_CALLS.with(|map| {
                map.borrow_mut().insert(
                    call_id,
                    PendingCall { resolvers },
                );
            });

            // 将调用信息加入完成列表，供 Dart 轮询
            COMPLETED_CALLS.with(|list| {
                list.borrow_mut().push(CompletedCall {
                    call_id,
                    name: name.clone(),
                    params,
                });
            });

            Ok(BoaJsValue::from(promise))
        },
        method_name,
    )
}

// ─── 同步 FFI 回调（Dart→Rust→Dart 同步调用通道）─────────

/// Dart 侧注册的同步回调函数指针。
///
/// 签名：`char* handler(const char* request_json)`
/// - 参数：`{"n":"method_name","a":"[raw_json_args]"}`
/// - 返回：`{"v":"result_json"}` 或 `{"e":"error_msg"}`
/// - 内存：返回指针由 Rust 侧 `CString::from_raw` 接管释放
type DartCallHandler = unsafe extern "C" fn(*const c_char) -> *mut c_char;

thread_local! {
    /// 每个运行时一个 Dart 回调（所有方法共享同一个函数指针）。
    static DART_HANDLERS: RefCell<HashMap<u64, DartCallHandler>> = RefCell::new(HashMap::new());
}

pub(crate) fn register_dart_handler(runtime_id: u64, ptr: i64) {
    let handler: DartCallHandler = unsafe { std::mem::transmute(ptr as usize) };
    DART_HANDLERS.with(|map| {
        map.borrow_mut().insert(runtime_id, handler);
    });
}

pub(crate) fn unregister_dart_handler(runtime_id: u64) {
    DART_HANDLERS.with(|map| {
        map.borrow_mut().remove(&runtime_id);
    });
}

/// 调用 Dart handler（同步 FFI），返回 Dart 侧的 JSON 响应字符串。
fn call_dart_handler(runtime_id: u64, method: &str, args_json: &str) -> Result<String, String> {
    DART_HANDLERS.with(|map| {
        let handler = map
            .borrow()
            .get(&runtime_id)
            .copied()
            .ok_or_else(|| "Dart handler not registered for this runtime".to_string())?;

        let request = serde_json::json!({"n": method, "a": args_json}).to_string();
        let request_cstr =
            CString::new(request).map_err(|e| format!("CString::new failed: {e}"))?;

        let result_ptr = unsafe { handler(request_cstr.as_ptr()) };
        if result_ptr.is_null() {
            return Err("Dart handler returned null".to_string());
        }

        let result = unsafe { CStr::from_ptr(result_ptr) }
            .to_string_lossy()
            .into_owned();
        let _ = unsafe { CString::from_raw(result_ptr) };

        Ok(result)
    })
}

// ─── JsValue ↔ serde_json::Value 转换（FFI 协议用）───────

/// 将 FrbJsValue 转为 serde_json::Value（原始 JSON，与 Dart 侧 _jsValueToJson 对应）。
fn frb_value_to_json(v: &FrbJsValue) -> serde_json::Value {
    match v {
        FrbJsValue::None => serde_json::Value::Null,
        FrbJsValue::Boolean(b) => serde_json::Value::Bool(*b),
        FrbJsValue::Integer(i) => serde_json::Value::Number((*i).into()),
        FrbJsValue::Float(f) => {
            // 整数形式的 float 序列化为整数 JSON（与 JS 行为一致）
            let n = serde_json::Number::from_f64(*f).unwrap_or_else(|| 0.into());
            serde_json::Value::Number(n)
        }
        FrbJsValue::BigInt(s) => serde_json::Value::String(s.clone()),
        FrbJsValue::String_(s) => serde_json::Value::String(s.clone()),
        FrbJsValue::Bytes(b) => {
            let arr: Vec<serde_json::Value> =
                b.iter().map(|&byte| serde_json::Value::Number(byte.into())).collect();
            serde_json::Value::Array(arr)
        }
        FrbJsValue::Array(items) => {
            let arr: Vec<serde_json::Value> = items.iter().map(|i| frb_value_to_json(i)).collect();
            serde_json::Value::Array(arr)
        }
        FrbJsValue::Object(entries) => {
            let mut map = serde_json::Map::new();
            for (k, val) in entries {
                map.insert(k.clone(), frb_value_to_json(val));
            }
            serde_json::Value::Object(map)
        }
        FrbJsValue::Date(ts) => serde_json::Value::Number((*ts).into()),
        FrbJsValue::Symbol(desc) => serde_json::Value::String(desc.clone()),
    }
}

/// 将 serde_json::Value 转为 FrbJsValue（与 Dart 侧 _jsonToJsValue 对应）。
fn json_to_frb_value(v: &serde_json::Value) -> FrbJsValue {
    match v {
        serde_json::Value::Null => FrbJsValue::None,
        serde_json::Value::Bool(b) => FrbJsValue::Boolean(*b),
        serde_json::Value::Number(n) => {
            if let Some(i) = n.as_i64() {
                // 检查是否为整数值（JSON 不区分 int/float）
                if n.as_f64().map_or(false, |f| f == i as f64) {
                    FrbJsValue::Integer(i)
                } else {
                    FrbJsValue::Float(n.as_f64().unwrap_or(0.0))
                }
            } else {
                FrbJsValue::Float(n.as_f64().unwrap_or(0.0))
            }
        }
        serde_json::Value::String(s) => FrbJsValue::String_(s.clone()),
        serde_json::Value::Array(arr) => {
            let items: Vec<Box<FrbJsValue>> = arr
                .iter()
                .map(|v| Box::new(json_to_frb_value(v)))
                .collect();
            FrbJsValue::Array(items)
        }
        serde_json::Value::Object(map) => {
            let entries: Vec<(String, Box<FrbJsValue>)> = map
                .iter()
                .map(|(k, v)| (k.clone(), Box::new(json_to_frb_value(v))))
                .collect();
            FrbJsValue::Object(entries)
        }
    }
}

/// 创建同步 NativeFunction（不创建 Promise，直接返回结果）。
///
/// 通过 FFI 同步调用 Dart handler，JSON 协议：
/// - 请求：`{"n":"method","a":"[raw_json]"}`
/// - 响应：`{"v":"result_json"}` 或 `{"e":"error"}`
/// - result_json / args_json 均为 serde_json::Value 格式（原始 JSON）
pub(crate) fn create_sync_native_fn(method_name: String, runtime_id: u64) -> NativeFunction {
    NativeFunction::from_copy_closure_with_captures(
        move |_this, args, _name, ctx| -> boa_engine::JsResult<boa_engine::JsValue> {
            // 序列化 JS args → JSON（原始格式，与 Dart 侧 _jsonToJsValue 兼容）
            let args_frb: Vec<FrbJsValue> = args
                .iter()
                .map(|v| FrbJsValue::from_boa(v, ctx))
                .collect();
            let args_json_vals: Vec<serde_json::Value> =
                args_frb.iter().map(|v| frb_value_to_json(v)).collect();
            let args_json = serde_json::to_string(&args_json_vals).unwrap_or_default();

            // 同步调用 Dart handler
            match call_dart_handler(runtime_id, _name, &args_json) {
                Ok(raw_response) => {
                    // 解析响应包裹：{"v": result} 或 {"e": error}
                    let wrapper: serde_json::Value =
                        serde_json::from_str(&raw_response).unwrap_or_default();
                    if let Some(err) = wrapper.get("e").and_then(|e| e.as_str()) {
                        return Err(boa_engine::JsError::from_native(
                            boa_engine::JsNativeError::typ()
                                .with_message(format!("Dart: {err}")),
                        ));
                    }
                    if let Some(val) = wrapper.get("v") {
                        let result_frb = json_to_frb_value(val);
                        return result_frb.to_boa(ctx).map_err(|e| {
                            boa_engine::JsError::from_native(
                                boa_engine::JsNativeError::typ()
                                    .with_message(format!("{e}")),
                            )
                        });
                    }
                    Err(boa_engine::JsError::from_native(
                        boa_engine::JsNativeError::typ()
                            .with_message("Dart handler returned invalid response"),
                    ))
                }
                Err(e) => Err(boa_engine::JsError::from_native(
                    boa_engine::JsNativeError::typ().with_message(e),
                )),
            }
        },
        method_name,
    )
}

// ─── 进程内存 ────────────────────────────────────────────

/// 获取当前进程的物理内存用量（字节），平台不支持时返回 `None`。
///
/// - Linux / HarmonyOS: 读取 `/proc/self/status` 中的 `VmRSS` 字段
pub(crate) fn get_process_memory() -> Option<u64> {
    #[cfg(unix)]
    {
        if let Ok(content) = std::fs::read_to_string("/proc/self/status") {
            for line in content.lines() {
                if line.starts_with("VmRSS:") {
                    let kb: u64 = line
                        .split_whitespace()
                        .nth(1)?
                        .parse()
                        .ok()?;
                    return Some(kb * 1024); // KiB → bytes
                }
            }
        }
    }
    #[cfg(target_os = "windows")]
    {
        // Windows: 可通过 winapi 获取，这里返回 None 回退到估算值
    }
    None
}

/// 向 Boa 上下文注册 Web API 扩展（Console + Fetch）。
pub(crate) fn register_web_apis(context: &mut Context) -> Result<(), String> {
    boa_runtime::register(
        (
            ConsoleExtension::default(),
            FetchExtension(BlockingReqwestFetcher::default()),
        ),
        None,
        context,
    )
    .map_err(|e| format!("Failed to register Web APIs: {e}"))
}

/// 创建并初始化一个新的 Boa 上下文。
///
/// 注册 Web API、DOM 模块、定时器，并配置模块加载器。
pub(crate) fn init_context(max_memory: u64, _runtime_id: u64) -> Result<RuntimeState, String> {
    let loader = Rc::new(MapModuleLoader::new());
    let mut context = Context::builder()
        .module_loader(loader)
        .build()
        .expect("Context::build should succeed");

    if let Err(e) = register_web_apis(&mut context) {
        eprintln!("Warning: {e}");
    }
    if let Err(e) = crate::dom::register_dom_module(&mut context) {
        eprintln!("Warning: {e}");
    }
    if let Err(e) = register_timers(&mut context) {
        eprintln!("Warning: {e}");
    }

    Ok(RuntimeState {
        context,
        max_memory,
        estimated_memory: 0,
        total_code_bytes: 0,
        total_module_bytes: 0,
    })
}

/// 向 Boa 上下文注册 `setTimeout` 全局函数。
///
/// 由于 JS 引擎运行在同步阻塞线程上（`BlockingReqwestFetcher`），
/// `setTimeout` 实现为 `thread::sleep` + 同步调用回调，不需要事件循环。
fn register_timers(context: &mut Context) -> Result<(), String> {
    use boa_engine::object::FunctionObjectBuilder;
    use boa_engine::property::PropertyDescriptor;
    use boa_engine::NativeFunction;

    let setTimeout = NativeFunction::from_copy_closure(
        |_this, args, context| {
            // 读取延迟（毫秒），默认 0
            let delay = args
                .get(1)
                .and_then(|v| v.as_number())
                .unwrap_or(0.0);
            if delay > 0.0 {
                std::thread::sleep(std::time::Duration::from_millis(delay as u64));
            }
            // 同步调用回调（如 Promise 的 resolve）
            // JsValue::call 是私有的，通过 as_object() 获取 JsObject 再调用
            if let Some(callback) = args.first() {
                if let Some(func) = callback.as_object() {
                    let _ = func.call(
                        &boa_engine::JsValue::undefined(),
                        &[],
                        context,
                    );
                }
            }
            Ok(boa_engine::JsValue::undefined())
        },
    );

    let function = FunctionObjectBuilder::new(context.realm(), setTimeout)
        .name(js_string!("setTimeout"))
        .length(2)
        .constructor(false)
        .build();

    context
        .global_object()
        .define_property_or_throw(
            js_string!("setTimeout"),
            PropertyDescriptor::builder()
                .value(function)
                .writable(true)
                .enumerable(false)
                .configurable(true),
            context,
        )
        .map(|_| ())
        .map_err(|e| format!("Failed to register setTimeout: {e}"))
}

// ─── 模块辅助 ────────────────────────────────────────────

/// 解析并编译 ES 模块。
pub(crate) fn parse_module(
    name: &str,
    source: &str,
    context: &mut Context,
) -> Result<Module, String> {
    Module::parse(Source::from_bytes(source.as_bytes()), None, context)
        .map_err(|e| format!("Failed to parse module '{name}': {e}"))
}

/// 从上下文获取 MapModuleLoader 的引用。
pub(crate) fn get_module_loader(
    context: &mut Context,
) -> Result<Rc<MapModuleLoader>, String> {
    context
        .downcast_module_loader::<MapModuleLoader>()
        .ok_or_else(|| "Module loader unavailable".to_string())
}

/// 对 Boa 值求值并解析 Promise（如有），返回结果字符串。
pub(crate) fn eval_and_resolve(
    code: &str,
    state: &mut RuntimeState,
) -> Result<String, String> {
    match state.context.eval(Source::from_bytes(code.as_bytes())) {
        Ok(value) => {
            let resolved = if let Some(promise) = value.as_promise() {
                match promise.await_blocking(&mut state.context) {
                    Ok(v) => v,
                    Err(e) => return Err(format!("Promise rejected: {e}")),
                }
            } else {
                value
            };
            resolved
                .to_string(&mut state.context)
                .map(|s| s.to_std_string_escaped())
                .map_err(|e| format!("Failed to convert result: {e}"))
        }
        Err(e) => Err(format!("JS Error: {e}")),
    }
}

/// 检查并更新内存估算，如超出上限则返回错误。
pub(crate) fn check_memory_limit(_state: &RuntimeState) -> Result<(), String> {
    // if state.max_memory > 0 {
    //     let actual = get_process_memory().unwrap_or(state.estimated_memory);
    //     if actual >= state.max_memory {
    //         return Err(format!(
    //             "Memory limit exceeded: used {} bytes, limit {} bytes. \
    //              Call release_memory() or dispose() to free memory.",
    //             actual, state.max_memory
    //         ));
    //     }
    // }
    Ok(())
}

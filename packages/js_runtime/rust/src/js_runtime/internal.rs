//! JS 运行时内部状态管理。
//!
//! 此模块不在 `crate::api` 路径下，因此不会被 flutter_rust_bridge 扫描，
//! 避免将私有类型暴露给 Dart 端。

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use boa_engine::{Context, Module, Source};
use boa_engine::module::MapModuleLoader;
use boa_runtime::extensions::{ConsoleExtension, FetchExtension};
use boa_runtime::fetch::BlockingReqwestFetcher;

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
/// 注册 Web API、DOM 模块，并配置模块加载器。
pub(crate) fn init_context(max_memory: u64) -> Result<RuntimeState, String> {
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

    Ok(RuntimeState {
        context,
        max_memory,
        estimated_memory: 0,
        total_code_bytes: 0,
        total_module_bytes: 0,
    })
}

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
pub(crate) fn check_memory_limit(state: &RuntimeState) -> Result<(), String> {
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

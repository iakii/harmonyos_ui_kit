use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use boa_engine::{Context, Module, Source};
use boa_engine::module::MapModuleLoader;
use flutter_rust_bridge::frb;

use boa_runtime::extensions::{ConsoleExtension, FetchExtension};
use boa_runtime::fetch::BlockingReqwestFetcher;

/// 单个运行时的内部状态。
struct RuntimeState {
    context: Context,
    /// 内存上限（字节），0 表示不限制。
    max_memory: u64,
    /// 估算内存用量（字节）：已执行的代码 + 已加载的模块源码总量。
    estimated_memory: u64,
    /// 已执行的 JS 代码总字节数。
    total_code_bytes: u64,
    /// 已加载的模块源码总字节数。
    total_module_bytes: u64,
}

thread_local! {
    static RUNTIMES: RefCell<HashMap<u64, RuntimeState>> = RefCell::new(HashMap::new());
}

fn next_id() -> u64 {
    use std::sync::atomic::AtomicU64;
    static NEXT_ID: AtomicU64 = AtomicU64::new(0);
    NEXT_ID.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}

fn register_web_apis(context: &mut Context) -> Result<(), String> {
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

/// 获取当前进程的物理内存用量（字节），平台不支持时返回 `None`。
///
/// - Linux / HarmonyOS: 读取 `/proc/self/status` 中的 `VmRSS` 字段
fn get_process_memory() -> Option<u64> {
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
        // use std::mem;
        // use windows_sys::Win32::System::ProcessStatus::{GetProcessMemoryInfo, PROCESS_MEMORY_COUNTERS};
        // ...
    }
    None
}

/// JS 运行时句柄。通过 [JsRuntime::create] 创建，使用完毕后调用 [JsRuntime::dispose] 释放。
pub struct JsRuntime {
    pub id: u64,
}

impl JsRuntime {
    /// 创建一个新的 JS 运行时，返回句柄。
    ///
    /// # 参数
    /// - `max_memory_bytes`: 可选的内存上限（字节），`null` 或 `0` 表示不限制。
    ///   超出上限后 [eval_js](Self::eval_js) 会返回错误。
    ///
    /// 使用完毕后必须调用 [dispose](Self::dispose) 释放资源。
    #[frb(sync)]
    pub fn create(max_memory_bytes: Option<u64>) -> Self {
        let id = next_id();

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

        RUNTIMES.with(|map| {
            map.borrow_mut().insert(
                id,
                RuntimeState {
                    context,
                    max_memory: max_memory_bytes.unwrap_or(0),
                    estimated_memory: 0,
                    total_code_bytes: 0,
                    total_module_bytes: 0,
                },
            );
        });

        Self { id }
    }

    // ─── 内存管理 ────────────────────────────────────────

    /// 获取当前运行时的**估算内存用量**（字节）。
    ///
    /// 估算值 = 已执行代码总字节数 + 已加载模块源码总字节数。
    /// 包含该运行时创建以来所有 `eval_js` 和 `preload_module` 调用的累计值。
    #[frb(sync)]
    pub fn memory_usage(&self) -> u64 {
        RUNTIMES.with(|map| {
            map.borrow()
                .get(&self.id)
                .map(|s| s.estimated_memory)
                .unwrap_or(0)
        })
    }

    /// 获取**所有运行时所在进程的物理内存**用量（字节）。
    ///
    /// - Linux / HarmonyOS: 读取 `/proc/self/status` 的 RSS（常驻集大小）。
    /// - 其他平台: 返回 `0`（不支持）。
    ///
    /// 该值反映的是整个进程的内存占用，而非单个运行时。
    #[frb(sync)]
    pub fn total_memory_usage() -> u64 {
        get_process_memory().unwrap_or(0)
    }

    /// 释放内存 —— 清理当前运行时中由 `WeakRef` 保持的对象。
    ///
    /// 调用后内存用量可能下降。若需完全重置内存，建议 `dispose()` 后重新 `create()`。
    #[frb(sync)]
    pub fn release_memory(&self) {
        RUNTIMES.with(|map| {
            if let Some(state) = map.borrow_mut().get_mut(&self.id) {
                state.context.clear_kept_objects();
                // 重置估算值（代码仍可执行，但分子已释放）
                state.estimated_memory = state.total_module_bytes;
                state.total_code_bytes = 0;
            }
        });
    }

    // ─── 模块管理 ────────────────────────────────────────

    /// 预加载一个 ES 模块，使其可通过 `import('name')` 动态导入。
    #[frb(sync)]
    pub fn preload_module(&self, name: String, source: String) -> Result<(), String> {
        RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.id)
                .ok_or_else(|| format!("Runtime {} not found", self.id))?;

            let module = Module::parse(Source::from_bytes(&source), None, &mut state.context)
                .map_err(|e| format!("Failed to parse module '{name}': {e}"))?;

            let loader = state
                .context
                .downcast_module_loader::<MapModuleLoader>()
                .ok_or_else(|| "Module loader unavailable".to_string())?;

            loader.insert(&name, module);

            // 更新内存估算
            let bytes = source.len() as u64;
            state.total_module_bytes += bytes;
            state.estimated_memory += bytes;

            Ok(())
        })
    }

    // ─── 代码执行 ────────────────────────────────────────

    /// 执行 JavaScript 代码，返回求值结果的字符串表示。
    ///
    /// 如已设置 `max_memory_bytes`，执行后若估算内存超过上限则返回错误。
    #[frb(sync)]
    pub fn eval_js(&self, code: String) -> Result<String, String> {
        RUNTIMES.with(|map| {
            let mut map = map.borrow_mut();
            let state = map
                .get_mut(&self.id)
                .ok_or_else(|| format!("Runtime {} not found", self.id))?;

            // 内存检查（执行前）
            if state.max_memory > 0 {
                let actual = get_process_memory().unwrap_or(state.estimated_memory);
                if actual >= state.max_memory {
                    return Err(format!(
                        "Memory limit exceeded: used {} bytes, limit {} bytes. \
                         Call release_memory() or dispose() to free memory.",
                        actual, state.max_memory
                    ));
                }
            }

            match state.context.eval(Source::from_bytes(&code)) {
                Ok(value) => {
                    let resolved = if let Some(promise) = value.as_promise() {
                        match promise.await_blocking(&mut state.context) {
                            Ok(v) => v,
                            Err(e) => return Err(format!("Promise rejected: {e}")),
                        }
                    } else {
                        value
                    };

                    // 更新内存估算
                    let code_bytes = code.len() as u64;
                    state.total_code_bytes += code_bytes;
                    state.estimated_memory += code_bytes;

                    // 内存检查（执行后）
                    if state.max_memory > 0 {
                        let actual = get_process_memory().unwrap_or(state.estimated_memory);
                        if actual >= state.max_memory {
                            return Err(format!(
                                "Memory limit exceeded: used {} bytes, limit {} bytes. \
                                 Call release_memory() or dispose() to free memory.",
                                actual, state.max_memory
                            ));
                        }
                    }

                    match resolved.to_string(&mut state.context) {
                        Ok(s) => Ok(s.to_std_string_escaped()),
                        Err(e) => Err(format!("Failed to convert result: {e}")),
                    }
                }
                Err(e) => Err(format!("JS Error: {e}")),
            }
        })
    }

    // ─── 生命周期 ────────────────────────────────────────

    /// 销毁运行时，释放其占用的所有资源。
    ///
    /// 调用后该句柄不再可用。
    #[frb(sync)]
    pub fn dispose(self) -> Result<(), String> {
        RUNTIMES.with(|map| {
            map.borrow_mut()
                .remove(&self.id)
                .map(|_| ())
                .ok_or_else(|| format!("Runtime {} not found", self.id))
        })
    }
}

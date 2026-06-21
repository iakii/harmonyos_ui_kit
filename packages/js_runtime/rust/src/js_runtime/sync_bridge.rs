//! 同步回调桥 —— 独立于 worker channel 的全局共享通道。
//!
//! Worker 线程通过此桥写入调用请求并等待，Dart 主线程通过 `#[frb(sync)]`
//! 方法直接读取/写入，不经过 worker channel，实现真正的同步 FFI 回调。
//!
//! 流程：
//! 1. JS 调用注册的同步函数 → worker 线程写请求到 `SYNC_BRIDGE` → condvar.wait()
//! 2. Dart 主线程定时调用 `poll_sync_calls` → 读取请求 → 执行 handler
//! 3. Dart 主线程调用 `resolve_sync_call` → 写响应 → condvar.notify_all()
//! 4. Worker 线程被唤醒 → 返回结果给 JS → JS 继续执行

use std::collections::HashMap;
use std::sync::{Arc, Condvar, Mutex};

/// 同步调用请求（JS→Dart）。
#[derive(Clone)]
pub(crate) struct SyncCallRequest {
    pub call_id: u64,
    pub name: String,
    /// JSON 序列化的参数数组
    pub args_json: String,
}

/// 同步调用响应（Dart→JS）。
struct SyncCallResponse {
    /// "v" 字段为成功结果的 JSON，或 "e" 字段为错误消息
    result_json: String,
    is_error: bool,
}

struct SyncBridgeInner {
    /// 待处理的调用请求（Dart 主线程轮询）
    pending: Vec<SyncCallRequest>,
    /// 已完成的响应（按 call_id 索引，worker 线程等待）
    completed: HashMap<u64, SyncCallResponse>,
}

/// 全局同步回调桥。
///
/// - `pending`: 新的调用请求队列（worker 写入，Dart 主线程读取）
/// - `completed`: 已完成的响应表（Dart 主线程写入，worker 读取）
/// - `condvar`: 用于 worker 线程等待 + Dart 主线程唤醒
static SYNC_BRIDGE: std::sync::LazyLock<Arc<(Mutex<SyncBridgeInner>, Condvar)>> =
    std::sync::LazyLock::new(|| {
        Arc::new((
            Mutex::new(SyncBridgeInner {
                pending: Vec::new(),
                completed: HashMap::new(),
            }),
            Condvar::new(),
        ))
    });

// ─── 全局唯一 ID ──────────────────────────────────────────

pub(crate) fn next_sync_call_id() -> u64 {
    use std::sync::atomic::AtomicU64;
    static NEXT_ID: AtomicU64 = AtomicU64::new(0);
    NEXT_ID.fetch_add(1, std::sync::atomic::Ordering::Relaxed)
}

// ─── Worker 线程侧（JS 执行期间）──────────────────────────

/// Worker 线程：将同步调用请求写入桥，并阻塞等待 Dart 端响应。
///
/// 返回 JSON 字符串：`{"v": result_json}` 或 `{"e": error_message}`。
///
/// 此函数由 `create_sync_native_fn` 的闭包调用，运行在 worker 线程上。
pub(crate) fn worker_send_and_wait(name: &str, args_json: &str) -> String {
    let call_id = next_sync_call_id();
    let (lock, cvar) = &**SYNC_BRIDGE;

    // 1. 写入请求
    {
        let mut inner = lock.lock().expect("SYNC_BRIDGE lock poisoned");
        inner.pending.push(SyncCallRequest {
            call_id,
            name: name.to_string(),
            args_json: args_json.to_string(),
        });
    }

    // 2. 等待响应（阻塞 worker 线程）
    loop {
        let inner = lock.lock().expect("SYNC_BRIDGE lock poisoned");
        if let Some(resp) = inner.completed.get(&call_id) {
            let result = if resp.is_error {
                format!(r#"{{"e":"{}"}}"#, resp.result_json)
            } else {
                format!(r#"{{"v":{}}}"#, resp.result_json)
            };
            return result;
        }
        // 释放锁并等待通知
        let _guard = cvar.wait(inner).expect("SYNC_BRIDGE condvar wait failed");
        // 被唤醒后重新检查
    }
}

// ─── Dart 主线程侧（通过 #[frb(sync)] 方法调用）───────────

/// Dart 主线程：拉取所有待处理的同步调用请求（排空队列）。
///
/// 返回一个元组列表：`(call_id, method_name, args_json)`。
/// Dart 端通过 `pollSyncCalls()` 调用此函数。
pub(crate) fn poll_pending_calls() -> Vec<(u64, String, String)> {
    let (lock, _cvar) = &**SYNC_BRIDGE;
    let mut inner = lock.lock().expect("SYNC_BRIDGE lock poisoned");
    std::mem::take(&mut inner.pending)
        .into_iter()
        .map(|req| (req.call_id, req.name, req.args_json))
        .collect()
}

/// Dart 主线程：回传成功结果给阻塞的 worker 线程。
///
/// [result_json] 是 Dart handler 返回值的 JSON 序列化字符串。
pub(crate) fn resolve_call(call_id: u64, result_json: String) {
    let (lock, cvar) = &**SYNC_BRIDGE;
    let mut inner = lock.lock().expect("SYNC_BRIDGE lock poisoned");
    inner.completed.insert(
        call_id,
        SyncCallResponse {
            result_json,
            is_error: false,
        },
    );
    cvar.notify_all();
}

/// Dart 主线程：回传错误给阻塞的 worker 线程。
pub(crate) fn reject_call(call_id: u64, error: String) {
    let (lock, cvar) = &**SYNC_BRIDGE;
    let mut inner = lock.lock().expect("SYNC_BRIDGE lock poisoned");
    inner.completed.insert(
        call_id,
        SyncCallResponse {
            result_json: error,
            is_error: true,
        },
    );
    cvar.notify_all();
}

# eval 长耗时任务取消机制

## 问题背景

当 `eval()` 执行长耗时 JS 任务时，用户返回上一页，页面 dispose，但 eval 仍在 Rust worker 线程中执行。调用方（`send_and_wait`）阻塞在 `rx.recv()` 上，无法取消等待。这导致：

1. Dart 侧的 `Future` 永远不会完成（或等到 eval 结束才完成，用户已离开页面）
2. Worker 线程被旧任务占用，下次请求需排队等待
3. `engine.close()` / `dispose()` 调用也阻塞，因为内部使用同一个 `send_and_wait`

**核心约束**：Boa 引擎的 `eval()` 是同步的，无法在中途打断 JS 执行。取消只能在**调用方等待侧**生效——让等待的 caller 提前返回，worker 则在后台继续执行完旧任务并丢弃结果。

## 设计概要

### Rust 侧

1. **JsError 新增 `Cancelled` 变体** — 取消时返回此错误
2. **WorkerHandle 新增 `cancel_gen: Arc<AtomicU64>`** — 代际计数器（generation counter）
3. **`send_and_wait` 改为超时轮询** — 用 `recv_timeout(100ms)` 循环，检测 cancel_gen 变化
4. **新增 `cancel_eval(runtime_id)`** — 递增 cancel_gen，唤醒所有等待中的 caller
5. **`JsRuntime` / `JsEngine` 新增 `cancel_eval()` 方法** — `#[frb(sync)]`，Dart 可直接调用
6. **`spawn_worker` 初始化 cancel_gen**

### Dart 侧

7. FRB codegen 自动为 `cancel_eval()` 生成 Dart Wrapper
8. **JsCallbackHandler.eval() 改造** — 接受 `CancelToken` 或返回可取消的 Future
9. **Provider dispose 时调用取消** — `detail_provider.dart` / `gallery_provider.dart`

### 代际计数器原理

```
cancel_gen: Arc<AtomicU64>  // 初始值 0

send_and_wait():
  gen = cancel_gen.load()     // 记录当前代际，例如 0
  send(cmd)
  loop:
    match rx.recv_timeout(100ms):
      Ok(result) => return result
      Timeout =>
        if cancel_gen.load() != gen:  // 被 cancel_eval 递增了
          return Err(Cancelled)
        // 否则继续等待

cancel_eval():
  cancel_gen.fetch_add(1)       // 递增 → 1

// 下一个 send_and_wait() 会记录 gen=1，不会被旧的 cancel 影响
```

## 详细修改计划

### 文件 1: `rust/src/api/js_error.rs`

```rust
// 新增变体
Cancelled {
    message: String,
},

// code() → "CANCELLED"
// is_recoverable() → true
// Display + classify_error 中也添加对应分支
```

### 文件 2: `rust/src/js_runtime/worker.rs`

**WorkerHandle 新增字段**:
```rust
pub(crate) struct WorkerHandle {
    pub sender: mpsc::Sender<WorkerCmd>,
    pub thread: Option<thread::JoinHandle<()>>,
    pub cancel_gen: Arc<AtomicU64>,  // NEW
}
```

**`send_and_wait` 重写**（核心逻辑）:
```rust
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;

fn send_and_wait<T>(
    runtime_id: u64,
    make_cmd: impl FnOnce(mpsc::Sender<Result<T, JsError>>) -> WorkerCmd,
) -> Result<T, JsError> {
    let (tx, rx) = mpsc::channel();
    let cancel_gen: Arc<AtomicU64>;
    {
        let map = WORKERS.lock()...;
        let handle = map.get(&runtime_id)...;
        cancel_gen = handle.cancel_gen.clone();
        handle.sender.send(make_cmd(tx))...;
    }
    // 超时轮询 + 取消检测
    loop {
        match rx.recv_timeout(Duration::from_millis(100)) {
            Ok(Ok(v)) => return Ok(v),
            Ok(Err(e)) => return Err(e),
            Err(mpsc::RecvTimeoutError::Timeout) => {
                // 每 100ms 检查是否被取消
                if cancel_gen.load(Ordering::SeqCst) != start_gen {
                    return Err(JsError::Cancelled {
                        message: "eval cancelled".into(),
                    });
                }
                // 继续等待
            }
            Err(mpsc::RecvTimeoutError::Disconnected) => {
                return Err(JsError::Internal {
                    message: "Worker thread disconnected".into(),
                });
            }
        }
    }
}
```

同理修改 `send_and_wait_raw` 和 `send_and_wait_str`。

**新增 `cancel_eval` 函数**:
```rust
pub(crate) fn cancel_eval(runtime_id: u64) {
    if let Ok(map) = WORKERS.lock() {
        if let Some(handle) = map.get(&runtime_id) {
            handle.cancel_gen.fetch_add(1, Ordering::SeqCst);
        }
    }
}
```

**`spawn_worker` 中初始化 cancel_gen**:
```rust
WORKERS.lock()...insert(runtime_id, WorkerHandle {
    sender: tx,
    thread: Some(handle),
    cancel_gen: Arc::new(AtomicU64::new(0)),
});
```

### 文件 3: `rust/src/api/runtime.rs`

```rust
impl JsRuntime {
    /// 取消当前正在执行的 eval 任务。
    ///
    /// 正在等待 eval 结果的调用方会立即收到 [JsError::Cancelled]。
    /// 工作线程中的 JS 执行会继续在后台完成（结果被丢弃），
    /// 取消后可以立即发起新的 eval 调用。
    #[frb(sync)]
    pub fn cancel_eval(&self) {
        worker::cancel_eval(self.id);
    }
}
```

### 文件 4: `rust/src/api/engine.rs`

```rust
impl JsEngine {
    /// 取消当前正在执行的 eval 任务。
    #[frb(sync)]
    pub fn cancel_eval(&self) {
        worker::cancel_eval(self.runtime_id);
    }
}
```

### 文件 5: Dart `JsCallbackHandler` (`lib/src/api/js_callback_handler.dart`)

为 `eval()` 添加取消支持：接受一个 `Future<void>? cancelSignal` 参数，当 cancelSignal 完成时调用 `engine.cancelEval()`。

```dart
Future<JsValue> eval(String code, {Future<void>? cancelSignal}) async {
    // ... 同之前，但在 cancelSignal 完成时调用 _engine.cancelEval()
}
```

### 文件 6: `lib/providers/js/detail_provider.dart`

在 `_detailWorker` 的 `onEvent` 中：
- 检查 `controller.isDisposed` 或类似的取消信号
- 如果页面已 dispose，不等待 eval 结果

### 文件 7: `lib/providers/js/gallery_provider.dart`

在 `_galleryWorker` 的 `onEvent` 中：
- 由于 isolate 是共享的（keepAlive），需要支持取消单个 compute 请求
- 通过 `IsolateManager` 的消息机制传递取消信号

### 运行 codegen

修改 Rust API 后必须运行：
```bash
cd packages/js_runtime && flutter_rust_bridge_codegen generate
```

## 验证方案

1. **Rust 编译**：`cd rust && cargo build` 确认无编译错误
2. **FRB codegen**：`flutter_rust_bridge_codegen generate` 确认生成成功
3. **Dart 分析**：`flutter analyze` 无新增错误
4. **集成测试**：在 App 中触发长耗时 JS 执行，在 eval 返回前导航返回，确认：
   - 页面正常退出，无挂起
   - 下一次请求正常执行（worker 未被阻塞）
   - 无内存泄漏（旧 worker 线程正常结束）

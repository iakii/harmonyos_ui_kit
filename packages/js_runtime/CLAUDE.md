# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Flutter FFI 插件，通过 `flutter_rust_bridge` 将 Rust 原生代码暴露给 Dart 层调用。Rust 端集成了 **Boa**（JavaScript 引擎），支持在原生层执行 JS 脚本。

## 常用命令

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze

# 重新生成 flutter_rust_bridge 绑定（修改 Rust API 后必须执行）
# 在 js_runtime 根目录下运行：
flutter_rust_bridge_codegen generate

# 构建 Rust 库（HarmonyOS 目标）
cd rust && cargo build --release --target aarch64-unknown-linux-ohos

# 本地调试构建（host 目标，无 cross-compile）
cd rust && cargo build
```

## 架构

```
js_runtime/
├── flutter_rust_bridge.yaml       # FRB codegen 配置（输出路径、入口类名）
├── pubspec.yaml                   # Flutter FFI 插件声明（6 平台均为 ffiPlugin: true）
├── lib/
│   ├── lib.dart                   # Barrel 导出：统一导出 src/frb/ 下所有公开 API
│   └── src/frb/                   # flutter_rust_bridge 自动生成的 Dart 代码
│       ├── frb_generated.dart     # 入口类 JsRuntimeLib + BaseEntrypoint 实现
│       ├── frb_generated.io.dart  # Native（非 Web）平台绑定
│       ├── frb_generated.web.dart # Web/WASM 平台绑定
│       └── api/hello.dart         # Rust hello() 的 Dart 封装（自动生成）
├── rust/
│   ├── Cargo.toml                 # crate: js_runtime, cdylib+staticlib, 依赖 boa_engine 0.21.1
│   └── src/
│       ├── lib.rs                 # 入口：mod frb_generated + pub mod api
│       ├── api/                   # FRB 公开 API（手写）
│       │   ├── mod.rs             # 公开 API 模块声明
│       │   ├── runtime.rs         # JsRuntime 低层 API
│       │   ├── engine.rs          # JsEngine 高层 API
│       │   ├── repl.rs            # JsRepl 交互式 REPL
│       │   ├── js_value.rs        # JsValue 枚举 + Boa 互转
│       │   ├── js_error.rs        # JsError 枚举 + 错误码
│       │   ├── eval_options.rs    # JsEvalOptions
│       │   ├── builtin_options.rs # JsBuiltinOptions + 预设
│       │   ├── module.rs          # JsModule
│       │   └── hello.rs           # 示例函数
│       ├── js_runtime/            # 内部实现（不暴露给 FRB）
│       │   ├── mod.rs
│       │   ├── internal.rs        # RuntimeState, init_context, NativeFunction 工厂
│       │   ├── worker.rs          # 工作线程：WorkerCmd + 全局 WORKERS 注册表
│       │   └── sync_bridge.rs     # 同步回调桥：全局 Mutex+Condvar
│       ├── dom.rs                 # DOM 解析模块（scraper）
│       └── frb_generated.rs       # FRB 自动生成（勿手动编辑）
├── cargokit/                      # 跨平台 Cargo 构建胶水（CMake/Gradle/Pod）
├── ohos/                          # HarmonyOS 原生工程（CMake + cargokit）
├── android/ ios/ linux/ macos/ windows/  # 其他平台工程
└── README.md
```

## 关键配置

`flutter_rust_bridge.yaml`:
- `rust_input: crate::api,boa_engine` — 将 Rust `api` 模块和 `boa_engine` 的类型暴露给 Dart
- `dart_output: lib/src/frb` — 生成的 Dart 代码输出到 `lib/src/frb/`
- `dart_entrypoint_class_name: JsRuntimeLib` — Dart 端入口类名（原为 `RustLib`，重构后改为 `JsRuntimeLib`）

## 核心设计

1. **纯 flutter_rust_bridge**: 不再使用 `dart:ffi` 直接调用或 `ffigen` 生成绑定，所有 FFI 调用通过 `JsRuntimeLib`（flutter_rust_bridge 生成）完成
2. **Boa 集成**: Rust 端依赖 `boa_engine`，rust_input 中包含 `boa_engine`，允许 Dart 通过 FRB 调用 JS 执行相关功能
3. **入口类 `JsRuntimeLib`**: 取代旧的 `RustLib`，通过 `JsRuntimeLib.init()` 初始化，通过自动生成的 Wrapper 函数调用 Rust
4. **工作线程模型**: 每个 `JsRuntime` 拥有一个专用 OS 线程（worker），Boa Context 在 worker 内运行。`eval`/`eval_file`/`eval_bytes`/`eval_path` 等方法通过 `mpsc` channel 向 worker 发送命令，Dart 端返回 `Future`（不阻塞主 isolate）。`create()`/`dispose()`/`memory_usage()` 等轻量操作保持 `#[frb(sync)]`
5. **同步回调桥**: `sync_bridge`（全局 `Mutex + Condvar`）独立于 worker channel，实现真正的同步 JS→Dart 回调——JS 调用后 Dart handler **立刻执行**并返回结果。Dart 端通过 Timer 定时轮询 `pollSyncCalls()` / `resolveSyncCall()` / `rejectSyncCall()`（均为 `#[frb(sync)]`，直接访问全局 Mutex，不排队）
6. **JS↔Dart 回调**: 推荐 `JsCallbackHandler`（基于 `registerSyncFunction` + `sync_bridge`，JS 调用立刻同步响应）；Promise 模式（`registerGlobalCallable` / `registerGlobalFunction` + `pollCalls` / `resolveCall` / `rejectCall`）作为高级选项

## 修改 Rust API 流程

1. 修改 `rust/src/api/` 下的 `.rs` 文件（添加函数/结构体/enum）
2. 在 `api/mod.rs` 中声明新模块（如果是新文件）
3. 运行 `flutter_rust_bridge_codegen generate`
4. FRB 会自动更新：
   - `rust/src/frb_generated.rs`（Rust 端调度代码）
   - `lib/src/frb/api/*.dart`（Dart 端 Wrapper）
   - `lib/src/frb/frb_generated.dart`（Dart 端入口）
5. 在 `lib/lib.dart` 中添加新的 export（如果是新文件）
6. 运行 `flutter pub get` 确认解析正常

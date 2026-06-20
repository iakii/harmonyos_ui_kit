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
│       ├── api/
│       │   ├── mod.rs             # 公开 API 模块声明
│       │   └── hello.rs           # 手写：hello() 函数（示例）
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
4. **JS↔Dart 回调**: 推荐 `JsCallbackHandler`（基于 `dart:ffi` NativeCallable + `registerSyncFunction`，JS 调用立刻同步响应）；Promise 模式（`registerGlobalCallable` / `registerGlobalFunction` + `pollCalls` / `resolveCall` / `rejectCall`）作为高级选项

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

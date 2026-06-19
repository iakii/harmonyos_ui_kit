# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

一个 Flutter 应用，以 **HarmonyOS NEXT**（OpenHarmony）为主要目标平台，同时兼容 Android、iOS、Windows、Linux、macOS、Web。通过 `flutter_rust_bridge` 调用 Rust 原生代码实现 FFI 交互，UI 层使用自研的 HarmonyOS 风格组件库。

## 常用命令

```bash
# Flutter 依赖安装
flutter pub get

# 静态分析
flutter analyze

# 运行测试（目前无测试文件）
flutter test

# 构建 Rust 库（在 js_runtime 目录下）
cd packages/js_runtime/rust && cargo build --release --target aarch64-unknown-linux-ohos

# 重新生成 flutter_rust_bridge 绑定代码
cd packages/js_runtime && flutter_rust_bridge_codegen generate
```

## 架构概览

```
rohos_app/
├── lib/main.dart                  # 应用入口，ProviderScope + MyApp；Rust FFI 通过 JsRuntimeLib（FRB）桥接
├── packages/
│   ├── harmonyos_ui/              # HarmonyOS NEXT 风格 UI 组件库（详见其 CLAUDE.md）
│   └── js_runtime/                     # Rust FFI 桥接插件（Flutter FFI plugin）
│       ├── flutter_rust_bridge.yaml  # FRB codegen 配置
│       ├── lib/
│       │   ├── lib.dart            # Barrel 导出
│       │   └── src/frb/            # FRB 生成的 Dart 代码
│       │       ├── api/hello.dart  # Rust hello() 的 Dart 封装
│       │       ├── frb_generated.dart  # 入口类 JsRuntimeLib
│       │       └── frb_generated.io.dart / .web.dart
│       ├── rust/                   # Rust 源码
│       │   ├── Cargo.toml          # crate: js_runtime (cdylib+staticlib), 依赖 boa_engine
│       │   └── src/
│       │       ├── lib.rs          # mod frb_generated + pub mod api
│       │       ├── api/            # 手写的公开 Rust API
│       │       └── frb_generated.rs  # FRB 自动生成（勿手动编辑）
│       ├── cargokit/               # 跨平台 Cargo 构建胶水
│       └── ohos/ android/ ios/ ... # 各平台原生工程
├── ohos/                          # HarmonyOS 原生工程
│   ├── build-profile.json5        # 签名配置 / SDK 版本 / 模块声明
│   ├── entry/
│   │   └── src/main/
│   │       ├── module.json5       # Ability 声明、权限（INTERNET）
│   │       └── ets/
│   │           ├── entryability/EntryAbility.ets  # 入口 Ability，注册 Flutter 插件
│   │           ├── pages/Index.ets                 # FlutterPage 容器
│   │           └── plugins/GeneratedPluginRegistrant.ets  # 插件注册（自动生成）
│   └── AppScope/app.json5
├── android/ ios/ windows/ linux/ macos/ web/  # 其他平台工程
└── pubspec.yaml                  # Flutter 项目配置，sdk ^3.9.2
```

## 核心技术栈

- **Flutter** + **Dart** 3.9.2 — UI 框架
- **flutter_rust_bridge** v2.13.0-beta.1 — Dart ↔ Rust FFI 桥接
- **Rust** 2021 edition — 原生逻辑（`cdylib` + `staticlib`）
- **Cargokit** — 跨平台 Rust 构建胶水（Android/iOS/Linux/macOS/Windows/HarmonyOS）
- **ArkTS** — HarmonyOS 原生壳（EntryAbility + FlutterPage）
- **harmonyos_ui** — 自研组件库，仿 HarmonyOS NEXT Design System

## 关键开发流程

### 修改 Rust API 后

1. 修改 `packages/js_runtime/rust/src/api/` 下的 `.rs` 文件
2. 如果是新建文件，在 `api/mod.rs` 中声明 `pub mod xxx;`
3. 在 `js_runtime` 目录运行 `flutter_rust_bridge_codegen generate`
4. 生成的代码位于 `packages/js_runtime/lib/src/frb/`（Dart）和 `packages/js_runtime/rust/src/frb_generated.rs`（Rust）
5. 如有新增 Dart 文件，在 `lib/lib.dart` 中添加对应的 `export`
6. 对 `js_runtime` 运行 `flutter pub get` 确认解析正常

### 构建 HarmonyOS

- 使用 **DevEco Studio** 打开 `ohos/` 目录
- 签名证书位于 `~/.ohos/config/`
- 当前目标：SDK 5.1.0（兼容）→ 6.0.2（目标），`arm64-v8a`
- Rust 构建产物 `libjs_runtime.so` 通过 `cargokit.cmake` 自动集成到原生构建

### 组件库开发

`harmonyos_ui` 是一个独立的 Flutter 库 package，有自己独立的 CLAUDE.md（见 `packages/harmonyos_ui/CLAUDE.md`）。它仿造 `fluent_ui` 的分层架构，所有组件遵循 `WidgetStyle > ThemeStyle > DefaultStyle` 三级样式解析。

### FFI 调用说明

`js_runtime` 使用 **flutter_rust_bridge** 作为唯一的 FFI 通道。入口类 `JsRuntimeLib`（定义于 `lib/src/frb/frb_generated.dart`），通过 `JsRuntimeLib.init()` 初始化后，调用自动生成的 Wrapper 函数（如 `hello()`）即可执行 Rust 代码。

不再使用 `dart:ffi` 直接调用或 `ffigen` 生成绑定的旧方案。

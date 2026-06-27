# AGENTS.md — rohos_app

一个 **HarmonyOS NEXT**（主）+ Android、iOS、Windows、Linux、macOS、Web 多平台 Flutter 应用。它使用 `flutter_rust_bridge` 调用基于 Rust 的 JavaScript 引擎（Boa）来抓取网站，并配有自定义的 HarmonyOS 风格 UI 组件库。

---

## 构建 / 测试 / 检查

```bash
# Flutter 依赖
flutter pub get

# 静态分析
flutter analyze

# 运行全部测试
flutter test

# 生成 Riverpod .g.dart 文件
dart run build_runner build --delete-conflicting-outputs

# 格式化 Dart 代码
dart format lib/

# Rust 构建（HarmonyOS 目标）
cd packages/js_runtime/rust && cargo build --release --target aarch64-unknown-linux-ohos

# Rust 本地调试构建（宿主目标）
cd packages/js_runtime/rust && cargo build

# 重新生成 flutter_rust_bridge 绑定（Rust API 变更后）
cd packages/js_runtime && flutter_rust_bridge_codegen generate

# Rust 测试
cd packages/js_runtime/rust && cargo test

# 死代码分析
make analyzer
```

`makefile` 封装了最常用的工作流：

| 命令 | 操作 |
|---|---|
| `make get` | 清理 + `flutter pub get` |
| `make clean` | `flutter clean` |
| `make runner` | `build_runner watch` |
| `make gen-rust` | `flutter_rust_bridge_codegen generate` |
| `make android-release` | 构建 Android APK（按 ABI 拆分） |
| `make window-release` | 构建 Windows EXE（通过 fastforge） |
| `make hap` | 构建 HarmonyOS HAP（通过 fastforge） |
| `make build-all` | 批量：Windows + Android + HAP |

Flutter SDK 约束：`^3.11.5`。Rust edition：2021，`flutter_rust_bridge` v2.13.0-beta.2。

---

## 架构

### 分层图

```
┌──────────────────────────────────────────────┐
│ presentation/  （Riverpod providers + 页面）  │
├──────────────────────────────────────────────┤
│ data/  （数据源 + 仓库实现）                   │
├──────────────────────────────────────────────┤
│ domain/  （实体 + 仓库接口）                   │
├──────────────────────────────────────────────┤
│ core/  （错误、网络、主题、存储）               │
└──────────────────────────────────────────────┘
```

**依赖规则**：`domain` 层零 Flutter/外部依赖。`data` 层依赖 `domain`。`presentation` 层依赖 `domain`。`core` 层跨所有层共享。

### 模块映射

| 模块 | Flutter 包 | 用途 |
|---|---|---|
| `lib/` | `rohos_app` | 主应用：Clean Architecture 结构 |
| `packages/harmonyos_ui/` | `harmonyos_ui` | HarmonyOS NEXT 风格 UI 组件库 |
| `packages/js_runtime/` | `js_runtime` | Rust FFI 插件（Boa JS 引擎） |
| `packages/hm_icon/` | `hm_icon` | HarmonyOS NEXT 符号图标字体 |

### lib/ 目录

```
lib/
├── main.dart              # 入口：ProviderScope + MyApp
├── app.dart               # MyApp：HarmonyOSApp.router
├── router.dart            # GoRouter 配置，带 ShellRoutes
│
├── core/
│   ├── error/             # AppException sealed 类 + Result<T>
│   ├── theme/             # themeModeProvider
│   ├── network/           # DioClient、BaseRepository、拦截器
│   ├── storage/           # SharedPreferences 单例（perfs）
│   ├── utils/             # 日期、日志辅助函数
│   └── extensions/        # string_ext、file_ext、widget_ext 等
│
├── domain/
│   ├── entities/          # GalleryItem、PluginInfo、SiteConfig、RustDailyTab...
│   ├── repositories/      # 抽象接口（JsGalleryRepository 等）
│   └── usecases/          # 占位（大部分逻辑在 provider 中）
│
├── data/
│   ├── datasources/
│   │   ├── remote/        # 基于 Dio：JsConfigRemoteDataSource、RustDailyRemoteDataSource
│   │   └── local/         # JsSourceLocalDataSource（SharedPreferences）
│   ├── repositories/      # 实现类：JsGalleryRepositoryImpl 等
│   └── models/            # 实体结构不同时的 DTO
│
└── presentation/
    ├── providers/
    │   ├── init/          # rustLibInitProvider、dioProvider
    │   ├── js_engine/     # jsEngineProvider（共享 JsEngine 单例）
    │   ├── js_gallery/    # galleryProvider、detailProvider、configProvider、pluginInfoProvider
    │   ├── rust_daily/    # rustDailyProvider
    │   └── core/          # counter、webf 状态
    ├── pages/
    │   ├── rust_daily/    # RustDailyPage、RustDailyDetailPage
    │   ├── js_gallery/    # GalleryPage、DetailPage、GalleryContentPage、JsIntroPage
    │   └── ...            # SplashPage、AppLayout、HarmonyOSPage、JsParsePage 等
    └── widgets/           # InfiniteScrollView、async_value_widget、loading、scrollbar 等
```

### 数据流

```
用户点击图库 → GoRouter 路由 → GalleryPage（页面）
  → ref.watch(galleryProvider(url, page))  （Riverpod 异步 provider）
    → JsEngine.eval() 调用 Rust Boa 引擎
      → JS 代码调用 client.fetchGallery(url, page)  （插件 .cjs）
        → HTTP 请求，HTML 解析，提取条目
      ← JsValue → JSON 字符串
    ← GalleryPageData ← 从 JSON 解析
  ← ListView / InfiniteScrollView 渲染条目
```

详情页会启动一个独立的 Dart `Isolate`，内含自己的 `JsEngine`。Isolate 通过 `SendPort` → `Stream<DetailLoadState>` 渐进式返回结果。

### js_runtime Rust 端

```
rust/src/
├── lib.rs                 # 入口：mod frb_generated + pub mod api + dom + encoding
├── frb_generated.rs       # 自动生成（请勿手动编辑）
├── api/
│   ├── mod.rs
│   ├── runtime.rs         # 底层 JsRuntime（每个实例一个工作线程）
│   ├── engine.rs          # 高层 JsEngine 封装
│   ├── repl.rs            # 交互式 REPL
│   ├── js_value.rs        # JsValue 枚举 + Boa 互操作
│   ├── js_error.rs        # JsError 枚举（密封）
│   ├── eval_options.rs
│   ├── builtin_options.rs
│   ├── module.rs
│   └── hello.rs           # 示例函数
├── js_runtime/
│   ├── internal.rs        # RuntimeState、init_context、NativeFunction
│   ├── worker.rs          # 工作线程 + WORKERS 注册表
│   └── dart_callbacks.rs  # FRB dart_callback 注册表
├── dom.rs                 # 合成 'dom' JS 模块（scraper）
└── encoding.rs            # 合成 'encoding' JS 模块（encoding_rs）
```

每个 `JsRuntime` / `JsEngine` 拥有一个专用 OS 工作线程。Boa 在其中运行。`eval()` 通过 `mpsc` 通道发送命令；Dart 端获得 `Future`。取消通过原子代际计数器实现。

---

## 关键文件和目录

| 路径 | 说明 |
|---|---|
| `lib/main.dart` | 应用入口 — `ProviderScope` 包裹 `MyApp` |
| `lib/app.dart` | `MyApp` — `HarmonyOSApp.router()` + 主题 + 路由 |
| `lib/router.dart` | GoRouter 配置：splash → ShellRoute(AppLayout) + GalleryLayout shell + Rust 路由 |
| `assets/js/config.json` | 图库站点配置：title → .cjs 资源路径映射（23 个条目） |
| `assets/js/*.cjs` | 图库抓取插件（meirentu.cjs、taotu.cjs、meitule.cjs 等） |
| `assets/views/` | 网页视图（tabs.html、hadaka.js） |
| `ohos/` | HarmonyOS 原生项目（ArkTS、module.json5、build-profile.json5） |
| `packages/harmonyos_ui/` | UI 库 — `HosPage`、`HosButton`、`HosTabBar`、`HarmonyOSApp`、主题系统 |
| `packages/js_runtime/` | Rust FFI 插件 — `JsRuntime`、`JsEngine`、`JsValue`、`JsError` |
| `packages/hm_icon/` | HMSymbolVF 图标字体包 |
| `pubspec.yaml` | 主应用依赖：go_router、dio、riverpod、hooks_riverpod、flutter_widget_from_html 等 |
| `flutter_rust_bridge.yaml` | FRB 代码生成配置（位于 js_runtime/ 内） |
| `makefile` | 全平台构建自动化 |

**`pubspec.yaml` 中值得注意的依赖覆盖**：`flutter_widget_from_html`、`path_provider`、`url_launcher`、`video_player` — 全部通过 `gitcode.com` fork 以兼容 OHOS。

---

## 编码规范

### Dart

- **状态管理**：Riverpod + 代码生成（`@riverpod` + `build_runner`）。Freezed 尚未广泛使用（仅在 js_runtime 的 Dart 侧使用）。
- **错误处理**：`AppException` sealed 类层级（`NetworkException`、`AuthException`、`TimeoutException`、`ParseException`、`UnknownException`）+ `Result<T>` sealed 类（`Success` / `Failure`）。仓库方法返回 `Result<T>`。
- **模式匹配**：Dart 3 sealed 类 + 全面 `switch` 穷尽匹配。
- **命名**：文件/文件夹使用 `snake_case`。类名使用 `PascalCase`。Provider 名使用 `camelCase`（例如 `galleryProvider`）。
- **Part 文件**：Riverpod `.g.dart` 文件使用 `part of` 引入源文件（例如 `gallery_provider.dart` + `gallery_provider.g.dart`）。
- **导入**：跨 `lib/` 使用 `package:` 导入，不使用相对导入。
- **网络**：`DioClient` 封装 `Dio`，带认证/日志/错误拦截器。`BaseRepository.safeCall()` 将 Dio 调用包装为 `Result<T>`。

### Rust

- **FRB 同步/异步**：同步操作（create、cancel、memory_usage）使用 `#[frb(sync)]`。长时间运行的 `eval()` 使用异步。
- **工作线程**：每个 `JsRuntime` 通过 `worker.rs` 获得一个专用 OS 线程。所有 Boa 操作都在该线程内执行。
- **命名**：函数/变量使用 `snake_case`，类型使用 `PascalCase`。模块组织按 `api/`（公开）和 `js_runtime/`（内部）划分。
- **错误类型**：`JsError` 在 Rust 侧，以 `Result<JsValue, JsError>` 返回。

### 生成代码

- `frb_generated.rs` / `frb_generated.dart` — **请勿手动编辑**，始终通过 `flutter_rust_bridge_codegen generate` 重新生成。
- `*.g.dart` — Riverpod 生成代码，通过 `dart run build_runner build` 重新生成。

---

## Git 工作流

- **远程仓库**：`https://github.com/iakii/harmonyos_ui_kit.git`
- **分支**：`master`
- **提交风格**：中文提交信息，带常规前缀（`feat:`、`refactor:`、`fix:`），例如 `feat: 新增漫画简介页面，增强信息卡片和简介展示功能`。
- **近期模式**：面向功能的提交，通常聚焦于单个页面或组件。

---

## CI/CD

仓库中未检测到 CI 配置。测试在本地通过 `flutter test` 运行。构建通过 `make` 目标或 DevEco Studio（HarmonyOS）手动执行。

---

## AI 代理提示

1. **修改 Rust API 后务必重新生成 FRB 绑定**。运行 `cd packages/js_runtime && flutter_rust_bridge_codegen generate`。遗漏此步骤是最常见的错误。
2. **修改 provider 注解后必须重新生成 Riverpod `.g.dart` 文件**：`dart run build_runner build --delete-conflicting-outputs`。如果直接编辑 `.g.dart` 文件，你的更改会被覆盖。
3. **JsEngine 在独立的 OS 线程（Rust worker）中运行 eval**，但通过 `engine.register()` 注册的 Dart 回调走 FRB 的 `dart_callback` 机制。如果遇到死锁，很可能是因为需要使用 `eval_raw()` 而非 `eval()`（以避免回调与 Promise-await 的争用）。
4. **取消模式**：始终通过 `.whenOrNull(cancelled: (_) => true)` 处理 `JsError.cancelled` —— 这是正常的关闭路径，不是错误。
5. **`assets/js/` 中的 `.cjs` 抓取器文件**遵循插件契约：它们导出一个包含 `fetchGallery(url, page)`、`fetchDetails(url)`、`fetchTags()` 和 `pluginInfo` 的 `default` 对象。编写新抓取器前请先研究现有文件。
6. **HarmonyOS 覆盖**：许多包在 `pubspec.yaml` 中有 `git:` 依赖覆盖，指向 `gitcode.com` 上的 OHOS 兼容 fork。升级这些包前务必确认 OHOS 兼容性。
7. **主题系统**（`harmonyos_ui`）：组件样式解析顺序为 `WidgetStyle > ThemeStyle > DefaultStyle`。添加新组件时请遵循此模式。
8. **Splash → 初始加载**：应用从 `/splash` 启动，通过 `rustLibInitProvider` 等待 `JsRuntimeLib.init()` 完成，然后导航到 `/`。如果修改初始化流程，请确保导航仍能正常触发。

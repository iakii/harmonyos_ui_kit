# Flutter 架构最佳实践重构计划

## 背景

当前项目所有代码集中在 `lib/pages/` 的 7 个文件中，没有分层架构：
- 无 HTTP 网络框架（无网络请求能力）
- 无状态管理库（所有状态用 `setState` 管理）
- 路由、业务逻辑、UI 全部耦合在 `main.dart` 和页面文件中

目标：遵循 Flutter 最佳实践，引入 **Dio** 网络框架和 **Riverpod** 状态管理，建立清晰的分层架构。

## 分层架构设计

```
lib/
├── main.dart                  # 入口：FlutterBinding + ProviderScope
├── app.dart                   # MyApp（ConsumerWidget）+ 主题/Router 配置
├── router.dart                # GoRouter 配置（从 main.dart 抽取）
├── models/                    # 数据模型（Dart 3 sealed class）
│   ├── app_exception.dart     # 异常层级（Network/Auth/Timeout/Parse/Unknown）
│   └── result.dart            # Result<T> 密封类（Success/Failure）
├── services/                  # 基础设施服务
│   └── api/                   # Dio HTTP 封装
│       ├── dio_client.dart    # Dio 单例 + 拦截器链
│       ├── api_exception.dart # DioException → AppException 映射
│       └── interceptors/      # 拦截器
│           ├── auth_interceptor.dart    # Token 注入 + 401 处理
│           ├── error_interceptor.dart   # 错误转换
│           └── log_interceptor.dart     # 请求日志
├── repositories/              # 数据仓库（协调网络/本地数据）
│   └── base_repository.dart   # 通用 safeCall 模式
├── providers/                 # Riverpod 状态管理
│   ├── dio_provider.dart      # Dio 实例 Provider
│   ├── theme_provider.dart    # 主题模式（light/dark/system）
│   ├── counter_provider.dart  # 计数器（迁移 harmony.dart 的 setState）
│   └── rust_bridge_provider.dart  # RustLib 初始化 Provider
├── pages/                     # UI 页面（已存在，逐步迁移）
│   ├── harmony.dart           # → 迁移到 HookConsumerWidget
│   ├── js_parse.dart          # → 迁移到 HookConsumerWidget
│   ├── glass_page.dart        # → 迁移到 HookConsumerWidget
│   ├── glass_kit.dart         # 不变
│   ├── immersive.dart         # 不变
│   ├── layout.dart            # 微调（可选）
│   └── bottom_bar.dart        # 不变
└── widgets/                   # 可复用组件
    └── async_value_widget.dart # AsyncValue 三态渲染（loading/error/data）
```

## 新增依赖

```yaml
dependencies:
  dio: ^5.8.0+1              # HTTP 网络框架
  hooks_riverpod: ^2.6.1     # Riverpod + flutter_hooks 集成
  logger: ^2.5.0             # 结构化日志（Dio 拦截器使用）
```

已存在不需添加的依赖：`flutter_hooks`, `go_router`

## 实施步骤（按依赖顺序）

### 阶段 1：基础模型层

1. **`pubspec.yaml`** — 添加 `dio`, `hooks_riverpod`, `logger` 依赖，执行 `flutter pub get`
2. **`lib/models/app_exception.dart`** — 创建 sealed class 异常体系
3. **`lib/models/result.dart`** — 创建 `Result<T>` 泛型密封类（Success/Failure）

### 阶段 2：网络层（Dio 封装）

4. **`lib/services/api/api_exception.dart`** — `mapDioException()` 函数，将 DioException 映射到 AppException
5. **`lib/services/api/interceptors/auth_interceptor.dart`** — Token 注入拦截器
6. **`lib/services/api/interceptors/error_interceptor.dart`** — 错误拦截器（调用 mapDioException）
7. **`lib/services/api/interceptors/log_interceptor.dart`** — 请求/响应日志拦截器
8. **`lib/services/api/dio_client.dart`** — Dio 客户端封装（BaseOptions + 拦截器链 + get/post/put/delete 方法）

### 阶段 3：Provider 层

9. **`lib/providers/dio_provider.dart`** — Dio 实例 Provider
10. **`lib/providers/theme_provider.dart`** — ThemeMode StateProvider
11. **`lib/providers/counter_provider.dart`** — 计数器 StateNotifierProvider（示例）
12. **`lib/providers/rust_bridge_provider.dart`** — RustLib 初始化 FutureProvider

### 阶段 4：应用壳重组织

13. **`lib/router.dart`** — 从 main.dart 提取 GoRouter 配置
14. **`lib/app.dart`** — MyApp ConsumerWidget（ProviderScope 内，调用 HarmonyOSApp.router）
15. **`lib/main.dart`** — 最小化入口：WidgetsFlutterBinding + ProviderScope + MyApp

### 阶段 5：共享组件

16. **`lib/widgets/async_value_widget.dart`** — AsyncValue<T> 通用渲染组件（loading/error/data 三态）

### 阶段 6：页面迁移

17. **`lib/pages/harmony.dart`** — StatefulWidget → HookConsumerWidget（计数器用 provider，UI 状态用 useState）
18. **`lib/pages/js_parse.dart`** — StatefulWidget → HookConsumerWidget（JS 运行时保持不变，本地状态用 Hook）
19. **`lib/pages/glass_page.dart`** — HookWidget → HookConsumerWidget（最小改动，仅加 WidgetRef 参数）

### 阶段 7（可选，待有 API 端点时）

20. **`lib/repositories/base_repository.dart`** — 通用 `safeCall<T>()` 模式

## 关键设计决策

- **不使用 freezed/json_serializable**：用 Dart 3 sealed class + record 替代，避免代码生成复杂度
- **使用 hooks_riverpod**：现有页面已用 `flutter_hooks`（useState），`HookConsumerWidget` 同时支持 hooks + Riverpod
- **RustLib.init() 改为 FutureProvider**：由 Riverpod 管理生命周期，异步初始化完成后页面才可使用 Rust 函数
- **渐进迁移**：每个阶段的改动独立可测，不会出现应用不可运行的状态

## 验证方法

1. `flutter pub get` — 确认依赖解析无冲突
2. `flutter analyze` — 无 lint 错误
3. 运行应用，确认以下功能正常：
   - 5 个页面全部可导航访问
   - 主题切换（light/dark/system）正常
   - HarmonyOSPage 计数器按钮正常工作（验证 Riverpod + Rust FFI）
   - JS Parse 页面 KossJS 初始化正常（验证 Provider 生命周期）
   - ImmersivePage / GlassPage / GlassKitPage 渲染正常
   - 底部导航栏切换路由正常

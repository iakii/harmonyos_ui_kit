# rohos_app lib/ 代码改进方案

> 审计日期：2026-06-27
> 审计范围：lib/ 全目录（含 core、domain、data、presentation 四层）

---

## 目录

- [P0 — 必须立即修复](#p0--必须立即修复)
- [P1 — 建议本轮迭代修复](#p1--建议本轮迭代修复)
- [P2 — 下个迭代修复](#p2--下个迭代修复)
- [P3 — 技术债务](#p3--技术债务)

---

## P0 — 必须立即修复

### 1. domain/data 层形同虚设

**问题**：Clean Architecture 的骨架（domain/repositories、data/repositories、domain/usecases）都定义好了，但 presentation 层完全绕过了它们，直接操作 Dio、JsEngine、SharedPreferences 和 Isolate。

| 数据流 | 应该怎么走 | 实际怎么走 |
|---|---|---|
| 图集列表 | Provider → UseCase → Repository → DataSource | Provider → `jsEngineProvider` → 直接 `eval()` |
| 详情加载 | Provider → UseCase → Repository → DataSource | Provider → 直接 `Isolate.spawn()` + `JsRuntimeLib` |
| JS 配置 | Provider → Repository → DataSource | Provider → 直接调用 `dioProvider` + `perfs` |
| 插件信息 | Provider → Repository → DataSource | Provider → 直接 `engine.eval()` |
| Rust Daily | Provider → Repository → DataSource | Provider → 直接 `dio.get()` + `parse()` |

**后果**：domain 层的 4 个 `*Repository` 接口、data 层的 4 个 `*RepositoryImpl`、domain/usecases 的 5 个 usecase 类，总计约 10 个文件全是死代码，没有任何 import 引用。

**改进方案**：
- 将 `JsGalleryRepositoryImpl` 中的 `getPage()` 逻辑使用到 Provider 中，让 Provider 依赖 Repository 而非直接依赖 JsEngine
- 将 `RustDailyRemoteDataSource` 中的解析逻辑唯一化，Provider 调用 Repository 而非直接 `dio.get()`
- 删除 `domain/usecases/` 下 5 个未使用的 usecase 文件（或等到真正需要时再创建）

### 2. `detail_provider.dart` 已被替代

`detail_provider.dart` 中定义了 `DetailLoad` provider（第 97-283 行），但实际详情页使用的是 `detailPageAccumulatorProvider`，`DetailLoad` 从未被引用。且该文件重复定义了 `DetailLoadState`（第 17-71 行），与 `domain/entities/detail_load_state.dart` 完全重复。

**改进方案**：
- 删除 `detail_provider.dart` 及 `detail_provider.g.dart`
- `domain/entities/detail_load_state.dart` 保留为唯一版本

---

## P1 — 建议本轮迭代修复

### 3. Isolate Worker 逻辑重复 3 次

`_WorkerInit`、`_Msg` 内部类在以下三处重复出现：
- `data/repositories/js_gallery_repository_impl.dart`
- `presentation/providers/js_gallery/detail_provider.dart`（删除后解决）
- `presentation/providers/js_gallery/detail_page_accumulator_provider.dart`

**改进**：抽取公共 `data/datasources/remote/detail_worker.dart`，统一 worker 函数。

### 4. RustDaily HTML 解析逻辑重复

`rust_daily_remote_datasource.dart` 和 `rust_daily_provider.dart` 的 `_fetch()` 做了完全一样的 Dio 请求 + `html/parser` 解析。

**改进**：让 Provider 通过 Repository → DataSource 链路调用，删除 Provider 中的重复解析逻辑。

### 5. domain/usecases 全部是死代码

`lib/domain/usecases/` 下 5 个 usecase 文件零引用：
- `js_gallery/get_gallery_page.dart`
- `js_gallery/get_gallery_detail.dart`
- `js_gallery/select_js_source.dart`
- `rust_daily/get_rust_daily_list.dart`
- `rust_daily/get_rust_daily_detail.dart`

**改进**：方案 A（推荐）删除；方案 B 保留但标记 `@visibleForTesting`。

---

## P2 — 下个迭代修复

### 6. Router 的 state.extra 类型不安全

多处使用 `(state.extra as Map<String, dynamic>)['url'] as String`，无编译期检查。

**改进**：定义类型安全的 Route 参数类（如 `GalleryDetailRouteArgs`）。

### 7. Extensions 过度设计

- **`string_ext.dart`（237 行）**：大量未使用的文件类型判断（`isZipFileName`、`isRarFileName` 等）
- **`numbric_ext.dart`**：`W`/`H` getter 与已有 `gap` 依赖重复；`WindowType` 在移动端无用途
- **`list_ext.dart`**：`firstWhereOrNull` 在 Dart 3.7+ 已有 `List.firstOrNull`
- **`file_ext.dart`**：`filename` getter 实现有 bug

**改进**：审计删除未使用方法，修复 bug。

### 8. `perfs` 单例设计不合理

`core/storage/perfs.dart` 封装了不必要的单例，`KEY_JS` 为 `late` 可变变量，Provider 直接 import 跳过了 DataSource 层。

**改进**：改为 Riverpod `Provider<SharedPreferences>` 注入。

### 9. `logger.dart` 设计问题

- `console` 类名小写开头违反 Dart 命名约定
- `_LogStorage` 每次初始化遍历文件系统
- 每条日志 `writeAsString(append)` 性能差

**改进**：统一命名，缓存日志批量写入，用 Riverpod 注入。

### 10. Provider 直接访问 SharedPreferences

`config_provider.dart`、`settings_provider.dart` 直接 import `perfs`。

**改进**：通过 JsSourceLocalDataSource 访问。

---

## P3 — 技术债务

### 11. BaseRepository 从未被继承

`core/network/base_repository.dart` 定义了 `safeCall()`，但 4 个 RepositoryImpl 没有一个继承它。

### 12. 硬编码的 1 秒等待

`rust_bridge_provider.dart` 中 `await waitTime(1 * 1000)`。

**改进**：依赖 `JsRuntimeLib.init()` 的 Future 完成。

### 13. Isolate 反复创建销毁

每次进入详情页 spawn/kill isolate。可引入 `isolate_manager` 池化复用。

### 14. 零单元测试

`test/` 只有默认 widget_test。优先为分页状态机、JSON 解析、`_parseConfigList()` 编写测试。

### 15. InfiniteScrollView（522 行）

包含两种模式，建议废弃 children 模式，仅保留 builder 模式。

### 16. webf_provider.dart 全部注释

如果 WebF 不再需要，删除该文件。

---

## 文件状态摘要

| 文件 | 状态 | 问题 |
|---|---|---|
| `domain/entities/*` | ✅ 良好 | 设计清晰 |
| `core/error/*` | ✅ 良好 | sealed class + Result 模式优秀 |
| `domain/repositories/*` | ⚠️ 死代码 | 未被调用 |
| `data/repositories/*` | ⚠️ 死代码 | 未被引用 |
| `domain/usecases/*` | ⚠️ 死代码 | 5 个文件零引用 |
| `presentation/providers/*` | ❌ 越权 | 绕过 domain/data 层 |
| `detail_provider.dart` | ❌ 可删除 | 已被替代 |
| `core/storage/perfs.dart` | ❌ 反模式 | 不必要的单例封装 |
| `core/extensions/*` | ⚠️ 冗余 | 大量未使用方法 |
| `router.dart` | ⚠️ 脆弱 | 类型不安全 |
| `logger.dart` | ⚠️ 可改进 | 命名违规、性能问题 |
| `test/` | ❌ 缺失 | 零业务测试 |

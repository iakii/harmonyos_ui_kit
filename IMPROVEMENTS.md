# rohos_app lib/ 代码改进方案

> 审计日期：2026-06-27
> 最后更新：2026-06-27
> 审计范围：lib/ 全目录（含 core、domain、data、presentation 四层）
> 处理进度：**19/21 项已完成**

---

## P0 — 必须立即修复

### 1. domain/data 层形同虚设 ✅ 已处理

**问题**：Clean Architecture 的骨架定义好了，但 presentation 层绕过它们直接操作 Dio、JsEngine、SharedPreferences 和 Isolate。

**处理**：
- 创建 `repository_providers.dart`，通过 Riverpod 注入 4 个 Repository
- `gallery_provider.dart` → 调用 `JsGalleryRepository`
- `plugin_info_provider.dart` → 调用 `JsPluginRepository`
- `rust_daily_provider.dart` → 调用 `RustDailyRepository`

### 2. `detail_provider.dart` 已被替代 ✅ 已处理

**处理**：删除 `detail_provider.dart` 及 `.g.dart`

---

## P1 — 建议本轮迭代修复

### 3. Isolate Worker 逻辑重复 3 次 ✅ 已处理

**处理**：抽取公共 `detail_worker.dart`，合并为单函数 `runDetailWorker`

### 4. RustDaily HTML 解析逻辑重复 ✅ 已处理

**处理**：`rust_daily_provider.dart` 改为通过 `RustDailyRepository` → `RustDailyRemoteDataSource` 调用

### 5. domain/usecases 全部是死代码 ✅ 已处理

**处理**：删除 5 个 usecase 文件

---

## P2 — 下个迭代修复

### 6. Router 的 state.extra 类型不安全 ✅ 已处理

**处理**：新增 `router_args.dart`（`GalleryRouteArgs` + `RustDailyRouteArgs`），router 及各页面传参改为类型安全方式

### 7. Extensions 过度设计 ✅ 已处理

**处理**：
- 删除 `list_ext.dart`、`widget_ext.dart`、`string_ext.dart`（237行）、`logger_ext.dart`
- `numbric_ext.dart` 从 153 行精简为 10 行（仅保留 `.W`/`.H`）

### 8. `perfs` 单例设计不合理 ✅ 已处理

**处理**：Provider 不再直接 import `perfs`，改为通过 `JsSourceLocalDataSource` 访问 SharedPreferences

### 9. `logger.dart` 设计问题 ✅ 已处理

**处理**：
- 删除未使用的 `console` 类（命名违规）
- `_LogStorage` → `_BufferedLogStorage`（StringBuffer + 500ms Timer flush）
- 新增 `@riverpod loggerProvider`，可通过 Riverpod 注入

### 10. Provider 直接访问 SharedPreferences ✅ 已处理

**处理**：`config_provider.dart` 和 `settings_provider.dart` 的 `perfs.KEY_JS` 操作全部改为 `JsSourceLocalDataSource` 调用

---

## P3 — 技术债务

### 11. BaseRepository 从未被继承 ✅ 已处理

**处理**：删除 `base_repository.dart`（零引用，且该模式不适用于项目以 DataSource 为主的架构）

### 12. 硬编码的 1 秒等待 ✅ 已处理

**处理**：`rust_bridge_provider.dart` 删除 `waitTime(1000)` 和 `perfs.init()`，直接依赖 `JsRuntimeLib.init()` 的 Future

### 13. Isolate 反复创建销毁 ✅ 已处理

**处理**：`js_gallery_repository_impl.dart` 删除未使用的 `getDetail()` 及 100+ 行 Isolate helper 代码。同步简化 `JsGalleryRepository` 接口。

### 14. 零单元测试 ⏳ 待处理

`test/` 只有默认 widget_test。优先为分页状态机、JSON 解析、`_parseConfigList()` 编写测试。

### 15. InfiniteScrollView（522 行） ✅ 已处理

**处理**：默认构造函数改为 `InfiniteScrollView.children()` 命名构造，与 `.builder()` 平级。两种模式均为显式命名构造，API 更清晰。

### 16. webf_provider.dart 全部注释 ⏳ 待处理

`core/webf_provider.dart` 中所有代码都被注释掉。如果 WebF 不再需要，应删除该文件。

---

## 文件状态摘要（更新后）

| 文件 | 状态 | 问题 |
|---|---|---|
| `domain/entities/*` | ✅ 良好 | 设计清晰 |
| `core/error/*` | ✅ 良好 | sealed class + Result 模式优秀 |
| `domain/repositories/*` | ✅ 已连接 | 通过 repository_providers 注入 |
| `data/repositories/*` | ✅ 已连接 | 被 Provider 引用 |
| `domain/usecases/*` | 🗑️ 已删除 | 5 个死代码文件 |
| `presentation/providers/*` | ✅ 已重构 | 通过 Repository 而非直接操作数据源 |
| `detail_provider.dart` | 🗑️ 已删除 | 被 Accumulator 替代 |
| `core/storage/perfs.dart` | ✅ 已隔离 | 仅 DataSource 内部使用 |
| `core/extensions/*` | ✅ 已精简 | 4 文件删除，numbric 精简 |
| `router.dart` | ✅ 已修复 | 类型安全 Route 参数类 |
| `logger.dart` | ✅ 已改造 | Riverpod 注入 + 缓冲写入 |
| `test/` | ❌ 缺失 | 零业务测试 |

---

## Git 历史

```
19 commits · +1,049 -1,699 lines
```

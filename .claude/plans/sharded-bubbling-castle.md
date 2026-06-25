# Flutter Clean Architecture 重构计划

## 背景

当前项目采用功能分层结构（`models/` / `providers/` / `pages/` / `services/` / `repositories/` / `widgets/` / `exts/`），文件散落在 `lib/` 根目录下，缺少清晰的分层边界。需要重构为标准的 **Flutter Clean Architecture**，提升代码的可维护性、可测试性和可扩展性。

## 目标架构

```
lib/
├── main.dart                       # 入口（不变）
├── app.dart                        # MyApp（更新 import）
├── router.dart                     # GoRouter（更新 import）
│
├── core/                           # 基础设施层
│   ├── error/                      # AppException, Result<T>
│   ├── theme/                      # theme_provider
│   ├── network/                    # DioClient, BaseRepository, interceptors
│   ├── storage/                    # SharedPreferences (perfs)
│   ├── utils/                      # date, logger
│   └── extensions/                 # string_ext, file_ext
│
├── domain/                         # 领域层（零外部依赖）
│   ├── entities/                   # 纯数据实体（无序列化逻辑）
│   ├── repositories/               # 仓库接口（抽象契约）
│   └── usecases/                   # 用例（薄层，封装业务意图）
│
├── data/                           # 数据层
│   ├── datasources/remote/         # 远程数据源（HTTP/JS）
│   ├── datasources/local/          # 本地数据源（SharedPreferences）
│   ├── repositories/               # 仓库实现
│   └── models/                     # DTO（带 fromJson/toJson）
│
└── presentation/                   # 表现层
    ├── providers/                  # Riverpod Providers
    ├── pages/                      # UI 页面
    └── widgets/                    # 共享组件
```

## 关键设计决策

1. **务实 DTO/Entity 策略**：当前数据类规模不大，Entity 保留 `fromJson` 构造函数，不强行拆分。未来如 data 层出现特有字段再拆分。

2. **Use Case 按需引入**：仅对跨层数据获取操作引入 use case。纯 UI 状态（counter、主题切换）和纯展示页面不需要。

3. **JsEngine 定位为基础设施**：`js_engine_provider.dart` 放在 `presentation/providers/js_engine/`，对 gallery 业务通过 repository impl 注入。

4. **vendor 代码不动**：`staggered_grid_view/` 整体移动到 `presentation/widgets/` 下，内容不变。

5. **`.g.dart` 文件跟随移动**：迁移完成后运行 `build_runner` 重新生成。

6. **推荐 `package:rohos_app/` 绝对路径导入**。

## 迁移步骤（共 11 步）

### 步骤 1：创建 `lib/core/` 目录
- 迁移 `lib/models/app_exception.dart` → `lib/core/error/app_exception.dart`
- 迁移 `lib/models/result.dart` → `lib/core/error/result.dart`
- 迁移 `lib/services/api/` → `lib/core/network/`（dio_client, api_exception, base_repository, interceptors）
- 迁移 `lib/services/perfs.dart` → `lib/core/storage/perfs.dart`
- 迁移 `lib/services/date.dart` → `lib/core/utils/date.dart`
- 迁移 `lib/services/logger.dart` → `lib/core/utils/logger.dart`
- 迁移 `lib/exts/` → `lib/core/extensions/`
- 迁移 `lib/providers/theme_provider.dart` → `lib/core/theme/app_theme_provider.dart`

### 步骤 2：更新全局 import 引用
- 搜索替换所有 `import 'package:rohos_app/models/app_exception.dart'` → `import 'package:rohos_app/core/error/app_exception.dart'`
- 同理更新所有 core 层文件的 import 路径
- 验证 `flutter analyze` 通过

### 步骤 3：创建 `lib/domain/entities/`
- 拆分迁移 models 为纯 entity：
  - `lib/models/plugin/gallery_item.dart` → `lib/domain/entities/gallery_item.dart` + `gallery_detail.dart`
  - `lib/models/plugin/plugin_info.dart` → `lib/domain/entities/plugin_info.dart` + `menu_item.dart`
  - `lib/models/plugin/site_config.dart` → `lib/domain/entities/site_config.dart`
  - `lib/models/rust_daily_data.dart` → `lib/domain/entities/rust_daily_tab.dart` + `rust_daily_page_data.dart`

### 步骤 4：创建 `lib/domain/repositories/`（仓库接口）
- `rust_daily_repository.dart` — `Future<Result<RustDailyPageData>> getList(...)`, `getDetail(...)`
- `js_config_repository.dart` — `getSites()`, `loadJsContent()`, `selectSource()`, `clear()`
- `js_gallery_repository.dart` — `Future<Result<GalleryPageData>> getPage(...)`, `Stream<DetailLoadState> getDetail(...)`
- `js_plugin_repository.dart` — `Future<Result<PluginInfo>> getPluginInfo()`

### 步骤 5：创建 `lib/domain/usecases/`
- `rust_daily/get_rust_daily_list.dart` — 封装分页列表获取
- `rust_daily/get_rust_daily_detail.dart` — 封装详情获取
- `js_gallery/get_gallery_page.dart` — 封装图集分页（JsEngine 协调）
- `js_gallery/get_gallery_detail.dart` — 封装详情流式加载（Isolate 管理）
- `js_gallery/select_js_source.dart` — 封装 JS 源选择（remote + local 协调）

### 步骤 6：创建 `lib/data/`（数据源 + 仓库实现）
- **新建 datasources**：
  - `data/datasources/remote/rust_daily_remote_datasource.dart` — 从 rust_daily_provider 抽出 HTTP+HTML 解析
  - `data/datasources/remote/js_config_remote_datasource.dart` — 从 config_provider 抽出网络请求
  - `data/datasources/local/js_source_local_datasource.dart` — 从 settings_provider 抽出 SharedPreferences 操作
- **新建 repository implements**：
  - `data/repositories/rust_daily_repository_impl.dart`
  - `data/repositories/js_config_repository_impl.dart`
  - `data/repositories/js_gallery_repository_impl.dart`（含 JsEngine + Isolate 管理）
  - `data/repositories/js_plugin_repository_impl.dart`
- **新建 DTO**（如需要与 entity 不同的数据表示）：
  - `data/models/gallery_page_dto.dart`
  - `data/models/gallery_detail_dto.dart`
  - `data/models/plugin_info_dto.dart`

### 步骤 7：更新 presentation providers
- `lib/providers/` → `lib/presentation/providers/`
- 按功能分组：`init/`、`rust_daily/`、`js_gallery/`、`js_engine/`、`core/`
- Provider 改为注入 repository 接口或 use case（通过 Riverpod 的 `ref.watch` 获取）
- `@riverpod` 注解的 provider（config、gallery、detail）更新 `part` 指令路径

### 步骤 8：移动 pages 和 widgets
- `lib/pages/` → `lib/presentation/pages/`
- 按功能分组：`rust_daily/`、`js_gallery/`，其余放根
- `lib/widgets/` → `lib/presentation/widgets/`（含 `staggered_grid_view/` 整体移动）

### 步骤 9：更新入口文件
- 更新 `main.dart`、`app.dart`、`router.dart` 所有 import 路径

### 步骤 10：重新生成代码
- 删除旧的 `.g.dart` 文件
- 运行 `dart run build_runner build` 在 presentation/providers 下重新生成

### 步骤 11：验证
- `flutter analyze` 零错误
- `flutter test` 通过
- 手动验证关键功能：Rust Daily 浏览、JS Gallery 加载、JS Parse playground

## 文件迁移快速对照表

### core/
| 旧 | 新 |
|---|---|
| `lib/models/app_exception.dart` | `lib/core/error/app_exception.dart` |
| `lib/models/result.dart` | `lib/core/error/result.dart` |
| `lib/providers/theme_provider.dart` | `lib/core/theme/app_theme_provider.dart` |
| `lib/services/api/dio_client.dart` | `lib/core/network/dio_client.dart` |
| `lib/services/api/api_exception.dart` | `lib/core/network/api_exception.dart` |
| `lib/services/api/interceptors/*` | `lib/core/network/interceptors/*` |
| `lib/repositories/base_repository.dart` | `lib/core/network/base_repository.dart` |
| `lib/services/perfs.dart` | `lib/core/storage/perfs.dart` |
| `lib/services/date.dart` | `lib/core/utils/date.dart` |
| `lib/services/logger.dart` | `lib/core/utils/logger.dart` |
| `lib/exts/strings.dart` | `lib/core/extensions/string_ext.dart` |
| `lib/exts/filesystem.dart` | `lib/core/extensions/file_ext.dart` |

### domain/
| 旧 | 新 |
|---|---|
| `lib/models/plugin/gallery_item.dart` | `lib/domain/entities/gallery_item.dart` + `gallery_detail.dart` |
| `lib/models/plugin/plugin_info.dart` | `lib/domain/entities/plugin_info.dart` + `menu_item.dart` |
| `lib/models/plugin/site_config.dart` | `lib/domain/entities/site_config.dart` |
| `lib/models/rust_daily_data.dart` | `lib/domain/entities/rust_daily_tab.dart` + `rust_daily_page_data.dart` |
| (新建) | `lib/domain/repositories/*` (4 个接口) |
| (新建) | `lib/domain/usecases/*` (5 个用例) |

### data/
均为新建：datasources（3 个）、repositories（4 个 impl）、models（3 个 DTO）

### presentation/
| 旧 | 新 |
|---|---|
| `lib/providers/*` | `lib/presentation/providers/` 按功能分组 |
| `lib/pages/*` | `lib/presentation/pages/` 按功能分组 |
| `lib/widgets/*` | `lib/presentation/widgets/` 保持结构 |

## 验证方法

```bash
# 每步完成后运行
flutter analyze

# 全部完成后
flutter analyze              # 零错误
flutter test                 # 现有测试通过

# 手动验证
# 1. 启动 app：Splash → 主界面
# 2. Rust Daily tab：列表加载、分页、详情跳转
# 3. JS Gallery tab：源选择、图集浏览、详情流式加载
# 4. Harmony tab：UI 组件展示、counter 操作
# 5. JS Parse tab：代码编辑、执行
# 6. 主题切换：亮色/暗色/系统
```

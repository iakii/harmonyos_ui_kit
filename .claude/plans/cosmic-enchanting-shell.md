# QuickJS Demo 页面实现计划

## Context

参考 [JSF（moluopro/jsf）](https://github.com/moluopro/jsf/blob/main/README-ZH.md) 的 API 展示风格，在项目中实现一个 JS 运行时能力 Demo 页面。JSF 是一个基于 QuickJS 的 Flutter JS 引擎，其 API 设计（eval、register、declareModule、Promise 等）与项目已有的 `js_runtime`（基于 Boa 引擎 + FRB）高度相似。

当前 `lib/presentation/pages/quickjs_page.dart` 文件已创建但内容为空，需要实现完整功能。

## 实现方案

### 文件变更清单

| # | 文件 | 操作 | 说明 |
|---|------|------|------|
| 1 | `lib/presentation/pages/quickjs_page.dart` | **重写** | QuickJS Demo 主页面（~500 行） |
| 2 | `lib/router.dart` | **修改** | 新增 `/quickjs` 路由 + import |

### 1. 页面架构

- **状态管理**: `ConsumerStatefulWidget` + `signals`（`signal<T>` + `Watch`），与 `js_parse.dart` 一致
- **页面容器**: `HosPage(leading: BackIcon(), title: 'QuickJS Demo', body: ListView(...))`
- **JS 引擎**: 单例 `late JsEngine _jsEngine`，`initState` 中创建，`dispose` 中 `close()`
- **内容布局**: 顶部状态栏 + 多个 `HosCard` 分组，每组展示一个功能

### 2. 功能区域（8 个 Group + 引擎状态栏）

每个 Group 包含：标题 + 简短描述 + 可编辑代码输入（`HosTextInput`，2-5 行）+ "Run" 按钮 + 结果/错误显示区域。

| Group | 功能 | 示例 JS / API | 关键 API |
|-------|------|--------------|----------|
| Engine Status Bar | 引擎状态 + 内存 + GC | 显示版本、内存用量、`[Run GC]` 按钮 | `memoryUsage()`, `runGc()` |
| 1. 基础求值 | 算术、字符串、布尔 | `40 + 2` | `engine.eval()` |
| 2. 类型互转 | Object→Map, Array→List, Date | `({name: 'Flutter', tags: [...]})` | `engine.eval()` + `fmtVal(JsValue)` |
| 3. Dart 回调 | `register()` JS 调用 Dart | `demoAdd(3, 7)` → 10 | `engine.register()` + `eval()` |
| 4. ES 模块 | `declareModules()` 内存模块 | `import('math').then(m => m.add(1,2))` | `engine.declareModules()` + `eval()` |
| 5. Promise/Async | promise 自动 resolve | `new Promise(r => r('done!'))` | `engine.eval()`（自动 resolve） |
| 6. 错误处理 | 语法/运行时/引用错误 | `syntax error`, `undefined.xxx` | `try-catch` + `JsError` 匹配 |
| 7. DOM 解析 | 内置 `dom` 模块 | `dom.querySelector(html, 'h1')` | `engine.eval()` + 内置 dom |
| 8. 编码转码 | 内置 `encoding` 模块 | `encoding.decode(bytes, 'gbk')` | `engine.eval()` + 内置 encoding |

### 3. 引擎生命周期

```dart
// initState → _initEngine()
_jsEngine = JsEngine.create(
  builtins: JsBuiltinOptions.all(),     // console + fetch
  modules: [
    JsModule(name: 'math', source: 'export function add(a,b){...}...'),
  ],
  runtimeOptions: JsRuntimeOptions(
    memoryLimit: BigInt.from(64 * 1024 * 1024),
    info: 'quickjs-demo',
  ),
);

// 注册 Dart 回调
await _jsEngine.register(name: 'demoAdd', func: _demoAddHandler);
await _jsEngine.register(name: 'demoConcat', func: _demoConcatHandler);
await _jsEngine.register(name: 'showMessage', func: _showMessageHandler);

// dispose → _jsEngine.close()
```

`JsRuntimeLib.init()` 已在应用启动时通过 `rustLibInitProvider` 全局完成，`JsEngine.create()` 可直接调用。

### 4. 关键设计决策

- **运行时选项**: `JsBuiltinOptions.all()` 启用 console + fetch
- **模块预注册**: math 工具模块在引擎创建时注册
- **Dart 回调**: 注册 `demoAdd`、`demoConcat` 两个实用回调 + `showMessage` 展示 Toast
- **并发控制**: 每次只能运行一个 section（简单全局 `isRunning` 信号），防止重复提交到同一 worker 线程
- **结果格式化**: 复用 `js_parse.dart` 中的 `fmtVal(JsValue)` 和 `fmtBytes(BigInt)` 模式（直接在页面内定义）
- **数组类型转换**: `JsValue.object` 返回 `List<(String, JsValue)>`，需在 `fmtVal` 中转换

### 5. 路由注册

在 `lib/router.dart` 的第一个 `ShellRoute`（AppLayout 包裹的 routes）中添加：

```dart
import 'presentation/pages/quickjs_page.dart' show QuickJSPage;

GoRoute(
  path: '/quickjs',
  builder: (context, state) => const QuickJSPage(),
),
```

### 6. 不做的内容

- 不提取共享 `fmtVal`/`fmtBytes` 到单独文件（保持改动最小，后续可做）
- 不修改 `js_parse.dart`
- 不在 HarmonyOS 主页添加导航入口（后续可做）

## 验证方案

1. 运行 `flutter analyze` 确认无静态分析错误
2. 检查 router.dart 中的 `/quickjs` 路由是否正确注册
3. 运行应用后导航到 `/quickjs`，验证所有 8 个功能区的 JS 代码执行结果正确
4. 验证 Dart 回调（Group 3）和 ES 模块（Group 4）功能正常
5. 验证错误处理（Group 6）能正确捕获语法/运行时错误
6. 验证 GC 按钮能正常触发并更新内存显示

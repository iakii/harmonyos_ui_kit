# 计划：引入 isolate_manager 重构子线程管理

## 上下文

当前 `detail_provider.dart` 使用手动 `dart:isolate`（`Isolate.spawn` + `ReceivePort`/`SendPort`），代码冗长且自行管理通信协议（`{'type': 'progress'/'final'/'error'}`）。`gallery_provider.dart` 在主 isolate 执行 JS `eval()`，可能阻塞 UI。

改用 `isolate_manager` 包统一管理后台 isolate，利用其内置的流式通信、生命周期管理、错误传播能力。

## 涉及文件

| 文件 | 改动类型 |
|------|---------|
| `pubspec.yaml` | 添加 `isolate_manager` 依赖 |
| `lib/providers/js/detail_provider.dart` | 重写，用 `IsolateManager.createCustom()` 替代手动 isolate |
| `lib/providers/js/gallery_provider.dart` | 重写，新增后台 isolate 执行 JS eval |

## 依赖

- `isolate_manager: ^6.3.2`（由 lamnhan066 维护，支持 `createCustom` + `stream` + `stop()`）

## 方案

### 1. detail_provider.dart — IsolateManager.createCustom

**Worker 函数**（替换 `_runInIsolate`）：

```dart
@pragma('vm:entry-point')
void _detailWorker(dynamic params) {
  IsolateManagerFunction.customFunction<Map<String, dynamic>, _WorkerInit>(
    params,
    onInit: (controller) async {
      // 1. 初始化 FRB + 创建 JsEngine（同原来）
      // 2. 注册 postMessage 回调 → controller.sendResult({'type': 'progress', ...})
      // 3. handler.eval(...) 阻塞执行
      // 4. 发送最终结果 → controller.sendResult({'type': 'final', ...})
      // 5. engine.close()
    },
    onDispose: (controller) {
      engine?.close();  // 确保 FFI 资源清理
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}
```

**Provider 侧**（替换手动 `ReceivePort`/`SendPort`/`Completer`）：

```dart
final detailLoadProvider = StreamProvider.autoDispose.family<...>((
  ref, url,
) {
  final controller = StreamController<DetailLoadState>();
  late final IsolateManager<Map<String, dynamic>, dynamic> isolate;

  // 创建 isolate（同原来在 startLoading 内加载 jsSource 后 spawn）
  // isolate.stream 替代 receivePort.listen
  // isolate.stop() 替代 receivePort.close()（且自动调 onDispose → engine.close()）

  ref.onDispose(() {
    isolate.stop();   // 安全：先调 onDispose 清理 FFI，再终止 isolate
    controller.close();
  });

  return controller.stream;
});
```

**关键差异**：
- `isolate.stream` 替代 `receivePort.listen`（消息格式不变，暂时保留 `{'type': ...}` 协议）
- `isolate.stop()` 替代 `receivePort.close()` — 会先触发 worker 的 `onDispose`（关闭 engine），再终止线程，避免 FFI 资源泄漏
- `IsolateManager` 内置 `completer` 管理，不需手动 `Completer<void>`
- 移除所有 `dart:isolate` 手动管理代码

### 2. gallery_provider.dart — 共享 IsolateManager + compute

**新建 `_galleryWorker`**：

```dart
@pragma('vm:entry-point')
void _galleryWorker(dynamic params) {
  IsolateManagerFunction.customFunction<String, _GalleryParams>(
    params,  // _GalleryInit{jsSource}
    onInit: (controller) async {
      await JsRuntimeLib.init();
      engine = JsEngine.create(
        modules: [JsModule(name: 'client', source: params.jsSource)],
        ...
      );
    },
    onEvent: (controller, message) async {
      // message = _GalleryParams{safeUrl, page}
      final result = engine.eval('''
        (async () => {
          const { default: client } = await import('client');
          return await client.getPage(${message.safeUrl}, ${message.page});
        })()
      ''');
      controller.sendResult(result.asStringSync ?? '');
    },
    onDispose: (controller) {
      engine?.close();
    },
  );
}
```

**新建 `galleryIsolateProvider`**（全局单例）：

```dart
final galleryIsolateProvider = FutureProvider<IsolateManager<String, _GalleryParams>>((ref) async {
  final jsSource = await rootBundle.loadString('assets/js/meitule.js');
  final isolate = IsolateManager.createCustom(
    _galleryWorker,
    initialParams: _GalleryInit(jsSource: jsSource),
    workerName: 'gallery',
  );
  ref.onDispose(() => isolate.stop());
  return isolate;
});
```

**修改 `galleryProvider`**，依赖 `galleryIsolateProvider`：

```dart
final galleryProvider = FutureProvider.family<GalleryPageData, ({String url, int page})>((
  ref, params,
) async {
  final isolate = await ref.watch(galleryIsolateProvider.future);
  final safeUrl = jsonEncode(params.url);
  
  final jsonStr = await isolate.compute(_GalleryParams(
    safeUrl: safeUrl,
    page: params.page,
  ));

  if (jsonStr.isEmpty || jsonStr == 'undefined') {
    throw NetworkException('获取图集数据失败: ${params.url}');
  }

  return GalleryPageData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
});
```

**关键点**：
- `galleryIsolateProvider` 是全局单例，一个 isolate 处理所有 gallery 请求
- 每次请求通过 `isolate.compute(params)` 发送到 worker → `onEvent` 处理 → `sendResult` 返回
- `compute()` 返回 `Future<R>`，天然适配 `FutureProvider`
- `isolate_manager` 内置请求队列，无需自己管理并发

### 3. pubspec.yaml

```yaml
dependencies:
  isolate_manager: ^6.3.2
```

### 4. 可选：Web Worker 支持

添加注解后运行代码生成：
```bash
dart run isolate_manager:generate
```

## 验证

1. `flutter pub get` 确认依赖解析
2. `flutter analyze` 无错误
3. 手动测试详情页：进入 → 等待图片加载 → 返回 → 确认无崩溃
4. 手动测试图集页：切换分类/翻页 → 确认数据正常加载
5. 快速进出详情页多次，确认无 isolate 泄漏

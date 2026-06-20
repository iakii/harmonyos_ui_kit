# JS 运行时 API 文档

`js_runtime` 提供嵌入式 JavaScript 运行时，基于 [Boa](https://github.com/boa-dev/boa)（纯 Rust ECMAScript 引擎），通过 `flutter_rust_bridge` 同步调用。参考 [FJS](https://github.com/iakii/harmonyos_ui_kit/blob/master/packages/fjs/README_zh.md) 架构设计，提供**两层 API** 和类型化的值/错误系统。

## 环境

1、添加 ohos-openssl
```bash
# ~/.ohos/
gh repo clone ohos-rs/ohos-openssl
```

2、~/.cargo/config.toml 中配置
```toml
AARCH64_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/arm64-v8a/"
ARMV7_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/armeabi-v7a/"
X86_64_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/x86_64/"
```

---

## 架构概览

```
┌─────────────────────────────────────────────┐
│                  Dart 端                     │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │  JsEngine     │  │  JsRuntime           │ │
│  │  (高层封装)    │  │  (低层 API)           │ │
│  │  · eval()         │  │  · create(options)   │ │
│  │  · call()         │  │  · eval() → JsValue  │ │
│  │  · register_      │  │  · dispose()         │ │
│  │    global_        │  │                      │ │
│  │    callable/      │  │                      │ │
│  │    function()     │  │                      │ │
│  │  · pollCalls()    │  │                      │ │
│  │  · resolveCall()  │  │                      │ │
│  │  · rejectCall()   │  │                      │ │
│  └──────┬───────┘  └──────────┬───────────┘ │
│         │                     │              │
│  ┌──────┴─────────────────────┴───────────┐ │
│  │  JsValue (freezed sealed class)        │ │
│  │  JsError (freezed sealed class)        │ │
│  │  CompletedCall (回调请求)               │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
                    │ FRB sync
┌─────────────────────┴───────────────────────┐
│                 Rust 端                      │
│  thread_local! { RUNTIMES: HashMap<u64, ..> }│
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │  Boa Context  │  │  DOM Module          │ │
│  │  + Console    │  │  (scraper 解析)      │ │
│  │  + Fetch      │  │                      │ │
│  │  + register_  │  │  Promise Bridge      │ │
│  │    global_    │  │  (CompletedCall 队列) │ │
│  │    callable/  │  │                      │ │
│  │    function() │  │                      │ │
│  └──────────────┘  └──────────────────────┘ │
└─────────────────────────────────────────────┘
```

**两层 API 设计**：
- **JsRuntime**（低层）：灵活控制运行时生命周期
- **JsEngine**（高层）：封装运行时管理，提供 `call()`、`register_global_callable()`、`register_global_function()` 等
- **CompletedCall**（回调请求）：JS→Dart 方法调用的统一请求类型，通过 `pollCalls()`/`resolveCall()`/`rejectCall()` 处理

---

## Dart API

### 导入

```dart
import 'package:js_runtime/lib.dart';
```

### JsValue —— 类型化的 JS 值

所有 `eval()` 返回 `JsValue`（freezed sealed class），支持 Dart 3 `switch` 模式匹配：

```dart
JsValue result = rt.eval(code: '42');

// 模式匹配
switch (result) {
  case JsValue_Integer(:final field0):
    print('整数: $field0');
  case JsValue_String_(:final field0):
    print('字符串: $field0');
  case JsValue_Array(:final field0):
    print('数组: ${field0.length} 项');
  default:
    print('类型: ${result.typeName()}');
}
```

**JsValue 变体**：

| 变体 | Dart 类型 | 说明 |
|------|----------|------|
| `JsValue_None` | — | `null` 或 `undefined` |
| `JsValue_Boolean` | `bool` | 布尔值 |
| `JsValue_Integer` | `PlatformInt64` | 整数 |
| `JsValue_Float` | `double` | 浮点数 |
| `JsValue_BigInt` | `String` | BigInt（字符串表示） |
| `JsValue_String_` | `String` | 字符串 |
| `JsValue_Bytes` | `Uint8List` | 二进制数据 |
| `JsValue_Array` | `List<JsValue>` | 数组 |
| `JsValue_Object` | `List<(String, JsValue)>` | 对象（键值对） |
| `JsValue_Date` | `PlatformInt64` | Unix 毫秒时间戳 |
| `JsValue_Symbol` | `String` | Symbol 描述 |

**便利扩展**（`JsValueExt`）：

```dart
// 同步类型判断（无需 await）
result.isNone       // bool
result.isNumber     // bool
result.isString     // bool
result.isArray      // bool

// 同步取值
result.asBooleanSync     // bool?
result.asIntegerSync     // PlatformInt64?
result.asStringSync      // String?
result.asArraySync       // List<JsValue>?
result.asMapSync         // Map<String, JsValue>?
result.asNumberSync      // double?
```

**工厂构造器**：

```dart
JsValue.none()
JsValue.boolean(true)
JsValue.integer(PlatformInt64.from(42))
JsValue.float(3.14)
JsValue.string("hello")
JsValue.bigInt("9007199254740993n")
JsValue.array([JsValue.integer(1), JsValue.integer(2)])
JsValue.object([("key", JsValue.string("value"))])
```

---

### JsError —— 结构化错误

`eval()` 等方法失败时抛出 `JsError`（freezed sealed class，实现 `FrbException`），可通过 `try/catch` + `switch` 处理：

```dart
try {
  rt.eval(code: '{{{{');
} on JsError catch (e) {
  switch (e) {
    case JsError_Syntax(:final message, :final line, :final column):
      print('语法错误 第${line}行: $message');
    case JsError_Type(:final message):
      print('类型错误: $message');
    case JsError_MemoryLimit(:final message):
      print('内存超限: $message');
    default:
      print('[${e.code()}] $e');
  }
}
```

**JsError 变体与错误码**：

| 变体 | 错误码 | 说明 |
|------|--------|------|
| `JsError_Syntax` | `SYNTAX` | 语法错误（含 line/column） |
| `JsError_Type` | `TYPE` | 类型错误 |
| `JsError_Reference` | `REFERENCE` | 引用错误（未定义变量） |
| `JsError_Runtime` | `RUNTIME` | 运行时错误 |
| `JsError_MemoryLimit` | `MEMORY_LIMIT` | 内存超限 |
| `JsError_StackOverflow` | `STACK_OVERFLOW` | 栈溢出 |
| `JsError_Internal` | `INTERNAL` | 内部/桥接错误 |
| `JsError_Generic` | `GENERIC` | 通用错误（兜底） |

---

### JsRuntime —— 低层 API

#### 创建运行时

```dart
// 默认配置（essential 内置模块，无内存限制）
final rt = JsRuntime.create();

// 自定义配置
final rt = JsRuntime.create(
  options: JsRuntimeOptions(
    memoryLimit: BigInt.from(100 * 1024 * 1024),  // 100MB 上限
    info: "my-runtime",                             // 调试标识
    builtins: JsBuiltinOptions.web(),               // 内置模块预设
  ),
);

// 旧版兼容（简单参数）
final rt = JsRuntime.createLegacy(
  maxMemoryBytes: BigInt.from(50 * 1024 * 1024),
);
```

#### 执行 JS 代码

```dart
// 新版：返回类型化 JsValue
JsValue result = rt.eval(code: '40 + 2');
print(result.asIntegerSync);  // 42

// 带选项执行
JsValue result = rt.evalWithOptions(
  code: 'var x = 1; x',
  options: JsEvalOptions(strict: true),
);

// 旧版兼容：返回字符串
String text = rt.evalJs(code: '40 + 2');  // "42"
```

#### 语法校验（不执行）

`validate()` 和 `validate_module()` 使用 `boa_parser` + `boa_ast` + `boa_interner` 解析源码为 AST，**不执行任何代码**，适用于预检：

```dart
// 校验 script 语法
try {
  JsRuntime.validate(code: 'var x = ;');  // 语法错误
} on JsError catch (e) {
  switch (e) {
    case JsError_Syntax(:final message, :final line, :final column):
      print('第${line}行第${column}列: $message');
    default: break;
  }
}

// 校验模块语法（preload 之前预检）
JsRuntime.validateModule(name: 'math', source: '''
  export function add(a, b) { return a + b; }
''');
```

#### 模块管理

```dart
// 预加载 ES 模块（动态 import）
rt.preloadModule(name: 'math', source: '''
  export function add(a, b) { return a + b; }
  export const VERSION = '1.0';
''');

// JS 端使用
rt.eval(code: '''
  (async () => {
    const math = await import('math');
    return math.add(3, 4);
  })()
''');
```

#### 内存管理

```dart
rt.memoryUsage();               // 估算内存（字节）
JsRuntime.totalMemoryUsage();   // 进程 RSS（Linux/HarmonyOS）
rt.setMemoryLimit(BigInt.from(50 * 1024 * 1024));  // 动态设限
rt.runGc();                     // 触发 GC（clear_kept_objects）
rt.releaseMemory();             // 同 runGc()
```

#### 生命周期

```dart
rt.dispose();  // 销毁运行时，释放资源
```

**JsRuntime 完整方法列表**：

| 方法 | 返回 | 说明 |
|------|------|------|
| `create({options})` | `JsRuntime` | 创建运行时（新 API） |
| `createLegacy({maxMemoryBytes})` | `JsRuntime` | 创建运行时（旧版兼容） |
| `eval({code})` | `JsValue` | 执行 JS，返回类型化值 |
| `evalWithOptions({code, options})` | `JsValue` | 带选项执行 |
| `evalJs({code})` | `String` | 执行 JS，返回字符串（旧版兼容） |
| `validate({code})` | `void` | **纯语法校验**（static，不执行，基于 boa_parser） |
| `validateModule({name, source})` | `void` | **模块语法校验**（static，不执行） |
| `preloadModule({name, source})` | `void` | 预加载 ES 模块 |
| `memoryUsage()` | `BigInt` | 估算内存用量 |
| `totalMemoryUsage()` | `BigInt` | 进程物理内存（static） |
| `setMemoryLimit({limitBytes})` | `void` | 设置内存上限 |
| `runGc()` | `void` | 触发 GC（boa_gc::force_collect） |
| `releaseMemory()` | `void` | 同 runGc() |
| `dispose()` | `void` | 销毁运行时 |

> 所有方法均为同步（`#[frb(sync)]`），在 Dart 主 isolate 线程执行。

---

### JsEngine —— 高层 API

`JsEngine` 封装运行时生命周期，提供更简洁的 API：

```dart
// 创建引擎（可同时注册初始模块）
final engine = JsEngine.create(
  builtins: JsBuiltinOptions.web(),
  modules: [
    JsModule(name: 'math', source: '''
      export function add(a, b) { return a + b; }
    '''),
  ],
  runtimeOptions: JsRuntimeOptions(
    memoryLimit: BigInt.from(100 * 1024 * 1024),
  ),
);

// 执行 JS
JsValue result = engine.eval(code: '1 + 2');

// 调用模块函数
JsValue sum = engine.call(
  module: 'math',
  method: 'add',
  params: [JsValue.integer(3), JsValue.integer(4)],
);
print(sum.asIntegerSync);  // 7

// JS→Dart 方法调用（注册 + 处理回调）
engine.registerGlobalFunction(name: 'compute');
engine.evalRaw(code: 'compute(21).then(r => console.log("结果:", r));');
final calls = engine.pollCalls();
for (final c in calls) {
  final x = c.params[0].asIntegerSync;
  engine.resolveCall(callId: c.callId, result: JsValue.integer(x * 2));
}
engine.runJobs();  // 触发 JS 侧 .then() 回调

// 或注册可构造函数（JS 可使用 new）
engine.registerGlobalCallable(name: 'Calculator');

// 注册更多模块
engine.declareModule(JsModule(name: 'utils', source: '...'));
engine.declareModules([...]);

// 内存管理
engine.memoryUsage();
engine.setMemoryLimit(BigInt.from(50 * 1024 * 1024));
engine.runGc();

// 关闭引擎
engine.close();
```

**JsEngine 方法列表**：

| 方法 | 返回 | 说明 |
|------|------|------|
| `create({builtins, modules, runtimeOptions})` | `JsEngine` | 创建引擎 |
| `eval({code})` | `JsValue` | 执行 JS |
| `evalWithOptions({code, options})` | `JsValue` | 带选项执行 |
| `call({module, method, params})` | `JsValue` | 调用模块导出函数 |
| `declareModule({module})` | `void` | 注册单个模块 |
| `declareModules({modules})` | `void` | 批量注册模块 |
| `evalRaw({code})` | `JsValue` | 执行 JS（不自动 resolve 顶层 Promise） |
| `registerGlobalCallable({name})` | `void` | 注册可构造 Promise 函数（JS 可 `new`） |
| `registerGlobalFunction({name})` | `void` | 注册纯 Promise 函数（不可 `new`） |
| `registerDartHandler({ptr})` | `void` | （内部）注册 Dart FFI 回调指针 |
| `registerSyncFunction({name})` | `void` | 注册同步函数（JS 调用立刻响应） |
| `pollCalls()` | `List<CompletedCall>` | 拉取 Promise 回调请求 |
| `resolveCall({callId, result})` | `void` | resolve JS Promise |
| `rejectCall({callId, error})` | `void` | reject JS Promise |
| `runJobs()` | `void` | 执行微任务（触发 `.then()` 回调） |
| `memoryUsage()` | `BigInt` | 内存用量 |
| `runGc()` | `void` | 触发 GC |
| `setMemoryLimit({limitBytes})` | `void` | 设置内存上限 |
| `close()` | `void` | 关闭引擎 |

---

## Dart↔JS 方法调用

`JsEngine` 提供两种 API 实现 JS→Dart 方法调用，均基于 Promise 机制：

1. **`register_global_callable`**：使用 Boa 的 `context.register_global_callable()`，注册的函数既可调用也可构造（`new`）
2. **`register_global_function`**：使用 `FunctionObjectBuilder` 手动构建不可构造的纯函数

两种 API 共用统一的 poll/resolve/reject 机制。

> **推荐使用 [JsCallbackHandler](#jsCallbackHandler-推荐) 替代**，基于 `registerSyncFunction` + FFI 同步回调，JS 调用立刻响应，和模块函数行为一致。

---

### JsCallbackHandler（推荐）

`JsCallbackHandler` 通过 `dart:ffi` 的 `NativeCallable.isolateLocal` 创建 C 函数指针，Rust NativeFunction 在 JS 调用时**直接同步调用 Dart 闭包并立刻拿到返回值**，无需 Promise、无需 poll loop。

```dart
import 'package:js_runtime/lib.dart';

final engine = JsEngine.create();
final handler = JsCallbackHandler(engine);

// 注册 —— JS 调用时立刻响应
handler.register('sum', (args) {
  return JsValue.integer(args[0].asIntegerSync + args[1].asIntegerSync);
});

// JS 端直接拿到结果，无需 await！
final result = handler.eval('sum(3, 4) + 10');
print(result.asIntegerSync);  // 17
```

#### 工作原理

```
JS 调用 sum(3, 4)
  → Boa NativeFunction（同步）
    → 序列化 args → JSON
    → FFI 同步调用 Dart _handleCall()
      → 解析 JSON, 查找 handler
      → 执行 fn(3,4) → 返回 7
    → 返回 7 给 JS
```

注册的同步方法在 JS 执行期间**立刻响应**（和 `console.log` 等内置函数一样同步执行）。

#### JsCallbackHandler API

| 方法 | 说明 |
|------|------|
| `register(name, handler)` | 注册同步回调（JS 调用立刻响应，无 Promise） |
| `unregister(name)` | 注销已注册的回调 |
| `eval(code)` | 执行 JS 并返回结果 |
| `registeredMethods` | 已注册的方法名列表 |
| `isRegistered(name)` | 检查是否已注册 |
| `engine` | 获取底层 `JsEngine` 实例 |

---

### Promise 回调机制（高级）

### 工作流程

```
Dart                              Rust                          JS
─────                             ────                          ──
engine.registerGlobalFunction("sum")
  → internal::create_native_fn()  → NativeFunction 创建
  → FunctionObjectBuilder          → 构建不可构造的 JsFunction
  → define_property_or_throw       → 绑定到 globalThis.sum
                                          ↓
engine.evalRaw(code)                      sum(3, 4)
  → ctx.eval(Source)                        → Promise 创建
                                            → {callId, "sum", [3,4]} 入队
engine.pollCalls()
  ← CompletedCall(callId, "sum", [3,4])
engine.resolveCall(callId, result)  ──→  Promise resolve(value)
engine.runJobs()                     ──→  .then(r => ...) 执行
```

> **重要**：JS 使用 `.then()` 模式，**不要**用顶层 `await`。`eval()` 内部会 `await_blocking` 顶层 Promise 导致死锁。

### CompletedCall 类型

```dart
class CompletedCall {
  final BigInt callId;        // 唯一 ID，用于 resolve / reject
  final String name;          // 注册的方法名
  final List<JsValue> params; // 调用参数
}
```

### 高级用法：自定义 handler 分发

```dart
class JsCallbackHandler {
  final JsEngine _engine;
  final Map<String, JsValue Function(List<JsValue>)> _handlers = {};

  JsCallbackHandler(this._engine);

  /// 注册一个纯函数回调
  void register(String name, JsValue Function(List<JsValue>) handler) {
    _handlers[name] = handler;
    _engine.registerGlobalFunction(name: name);
  }

  /// 注册一个可构造函数回调
  void registerCallable(String name, JsValue Function(List<JsValue>) handler) {
    _handlers[name] = handler;
    _engine.registerGlobalCallable(name: name);
  }

  /// 执行 JS 并自动处理所有回调
  JsValue eval(String code) {
    final result = _engine.evalRaw(code: code);
    drain();
    return result;
  }

  /// 处理所有待处理回调
  void drain() {
    final calls = _engine.pollCalls();
    for (final call in calls) {
      final handler = _handlers[call.name];
      if (handler != null) {
        try {
          final result = handler(call.params);
          _engine.resolveCall(callId: call.callId, result: result);
        } catch (e) {
          _engine.rejectCall(callId: call.callId, error: e.toString());
        }
      } else {
        _engine.rejectCall(
          callId: call.callId,
          error: 'Unknown method: ${call.name}',
        );
      }
    }
    if (calls.isNotEmpty) {
      _engine.runJobs();
    }
  }
}
```

### register_global_callable vs register_global_function

| 特性 | `register_global_callable` | `register_global_function` |
|------|---------------------------|---------------------------|
| Boa API | `context.register_global_callable()` | `FunctionObjectBuilder` + 手动绑定 |
| JS 调用 | `name(args)` ✅ | `name(args)` ✅ |
| JS 构造 | `new name(args)` ✅ | `new name(args)` ❌ TypeError |
| Promise 机制 | ✅ 共用 poll/resolve/reject | ✅ 共用 poll/resolve/reject |
| 适用场景 | 类/构造函数、需要 `new` 的 API | 纯函数、工具方法 |

---

### JsBuiltinOptions —— 内置模块配置

```dart
// 预设
JsBuiltinOptions.none();       // 无内置模块
JsBuiltinOptions.essential();  // Console（默认）
JsBuiltinOptions.web();       // Console + Fetch
JsBuiltinOptions.all();       // 同 web()

// 自定义
JsBuiltinOptions(
  console: true,
  fetch: false,
);
```

### JsEvalOptions —— 执行选项

```dart
JsEvalOptions.defaults();            // 默认
JsEvalOptions(strict: true);        // 启用严格模式
JsEvalOptions.strictMode();         // 同 strict: true
```

### JsModule —— 模块定义

```dart
JsModule(name: 'my-module', source: 'export const x = 1;');
```

---

## 内置 Web API

### Console（默认启用）

| 方法 | 说明 |
|------|------|
| `console.log(...args)` | 标准输出 |
| `console.error(...args)` | 标准错误 |
| `console.warn(...args)` | 标准输出（前缀 `[JS Warn]`） |
| `console.info(...args)` | 标准输出 |
| `console.debug(...args)` | 标准输出 |
| `console.trace(...args)` | 带调用栈的标准输出 |

### Fetch（JsBuiltinOptions.web() 启用）

```js
var r = await fetch('https://example.com/api');
var data = await r.json();    // or r.text(), r.blob(), r.arrayBuffer()
console.log(r.status, r.ok);
```

- 使用 `reqwest` **同步阻塞** HTTP 客户端
- 支持 `GET`、`POST`、自定义 headers、body 等

### Intl 国际化（启用 `intl_bundled` feature）

Boa 引擎已启用 `intl_bundled` feature，通过 `boa_icu_provider` 提供 ICU4X 国际化数据。JS 代码可直接使用：

```js
// 日期时间格式化
new Intl.DateTimeFormat('zh-CN').format(new Date());   // "2026/6/19"

// 数字格式化
new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(1234.56);
// "$1,234.56"

// 字符串比较
'ä'.localeCompare('z', 'de');  // -1
```

### 定时器（始终启用）

```js
setTimeout(() => console.log('later'), 1000);
setInterval(() => console.log('tick'), 500);
```

### 其他（始终启用）

| API | 说明 |
|-----|------|
| `TextEncoder` / `TextDecoder` | 文本编解码 |
| `URL` / `URLSearchParams` | URL 解析 |
| `queueMicrotask(fn)` | 微任务 |
| `structuredClone(obj)` | 深拷贝 |
| `atob()` / `btoa()` | Base64 |

### 垃圾回收

`runGc()` 调用 `boa_gc::force_collect()` 执行完整的**标记-清除** GC 循环，比简单的 `clear_kept_objects()` 更彻底：

```dart
rt.runGc();          // 完整 GC：force_collect() + clear_kept_objects() + 重置代码估算
rt.releaseMemory();  // 同 runGc()
```

- `boa_gc::force_collect()` — 对所有 GC 跟踪对象执行标记-清除
- 所有共享同一线程的 Boa 上下文共享同一个 GC 堆
- GC 阈值默认为 1MB 分配量，由 Boa 内部自动管理

---

## REPL 交互式求值

`JsRepl` 提供逐行求值能力，自动检测多行语句是否完整：

```dart
final repl = JsRepl.create();

// 单行完整语句 → 立即执行
var result = repl.evalLine(line: 'var x = 1;');
print(result.output);     // "1"
print(result.isComplete); // true

// 多行语句 → 自动累积
repl.evalLine(line: 'function foo() {');   // isComplete: false（需要续行）
repl.evalLine(line: '  return 42;');        // isComplete: false
result = repl.evalLine(line: '}');          // isComplete: true（执行整个函数）

// 访问内部运行时
final rt = repl.runtime;
rt.eval(code: 'foo()');  // "42"

// 强制求值（即使可能不完整）
repl.forceEval();

// 清空缓冲区
repl.clear();

// 查看未完成的代码
print(repl.pendingCode);

// 关闭
repl.close();
```

**JsRepl 方法**：

| 方法 | 返回 | 说明 |
|------|------|------|
| `create()` | `JsRepl` | 创建 REPL 实例 |
| `evalLine({line})` | `ReplResult` | 提交一行，自动检测完整性 |
| `forceEval()` | `ReplResult` | 强制执行缓冲区代码 |
| `clear()` | `void` | 清空缓冲区 |
| `pendingCode()` | `String` | 获取未完成代码 |
| `runtime()` | `JsRuntime` | 获取内部运行时 |
| `runGc()` | `void` | 触发 GC |
| `close()` | `void` | 关闭 REPL |

**ReplResult 字段**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `output` | `String` | 求值结果字符串 |
| `value` | `JsValue` | 结构化值 |
| `isComplete` | `bool` | 当前行是否完整语句 |

---

## DOM 解析模块

`"dom"` 模块在运行时创建时自动注册，提供 HTML 解析和 CSS 选择器能力（基于 [scraper](https://crates.io/crates/scraper)）。

### 导入

```js
const dom = await import('dom');
```

### API

所有查询函数接收 `(html: string, selector: string)`，返回 **JSON 字符串**（用 `JSON.parse()` 解析）。

#### `querySelectorAll(html, css)` → JSON 数组

```js
const elements = JSON.parse(dom.querySelectorAll(html, '.foo p'));
console.log(elements[0].tagName);   // "p"
console.log(elements[0].text);      // 文本内容
console.log(elements[0].innerHtml); // 内部 HTML
```

#### `querySelector(html, css)` → JSON 对象 或 null

```js
const el = JSON.parse(dom.querySelector(html, '#x span'));
if (el) {
  console.log(el.tagName);   // "span"
  console.log(el.classes);   // ["foo", "bar"]
}
```

#### `getElementsByTagName(html, tag)` → JSON 数组

```js
const pTags = JSON.parse(dom.getElementsByTagName(html, 'p'));
```

#### `getElementById(html, id)` → JSON 对象 或 null

```js
const el = JSON.parse(dom.getElementById(html, 'main'));
```

### ElementData 结构

```ts
interface ElementData {
  tagName: string;                  // 标签名（小写）
  text: string;                     // 文本内容
  innerHtml: string;                // 内部 HTML
  id: string;                       // id 属性
  classes: string[];                // class 列表
  attrs: [string, string][];       // 属性键值对
}
```

---

## 完整示例

### 示例 1：基础使用 + 类型化结果

```dart
final rt = JsRuntime.create(
  options: JsRuntimeOptions(
    memoryLimit: BigInt.from(50 * 1024 * 1024),
  ),
);

// 执行并获取类型化结果
JsValue result = rt.eval(code: '40 + 2');
print(result.asIntegerSync);  // 42
print(result.typeName());     // "number"

// 执行 JS 对象
JsValue obj = rt.eval(code: '({name: "test", count: 5})');
Map<String, JsValue>? map = obj.asMapSync;
print(map?['name']?.asStringSync);  // "test"

rt.dispose();
```

### 示例 2：错误处理

```dart
final rt = JsRuntime.create();

try {
  rt.eval(code: 'nonexistentVar + 1');
} on JsError catch (e) {
  switch (e) {
    case JsError_Reference(:final message):
      print('引用错误: $message');
    case JsError_Syntax(:final message, :final line, :final column):
      print('语法错误 第${line}行第${column}列: $message');
    case JsError_MemoryLimit():
      print('内存超限，请释放资源');
      rt.releaseMemory();
    default:
      print('[${e.code()}] $e');
  }
}

rt.dispose();
```

### 示例 3：JsEngine + 模块调用

```dart
final engine = JsEngine.create(
  builtins: JsBuiltinOptions.web(),
  modules: [
    JsModule(name: 'geo', source: '''
      export function circleArea(r) { return Math.PI * r * r; }
      export function sphereVolume(r) { return (4/3) * Math.PI * r * r * r; }
    '''),
  ],
);

// 调用模块函数
JsValue area = engine.call(
  module: 'geo',
  method: 'circleArea',
  params: [JsValue.float(5.0)],
);
print(area.asFloatSync);  // 78.5398...

engine.close();
```

### 示例 4：fetch + DOM 解析（JsEngine）

```dart
final engine = JsEngine.create(
  builtins: JsBuiltinOptions.web(),
);

final result = engine.eval(code: '''
  (async () => {
    const dom = await import('dom');
    const r = await fetch('https://example.com');
    const html = await r.text();

    const titleEl = JSON.parse(dom.querySelector(html, 'title'));
    return titleEl?.text ?? 'N/A';
  })()
''');

print(result.asStringSync);

engine.close();
```

### 示例 5：预加载模块 + HTML 解析（JsRuntime 低层 API）

```dart
final rt = JsRuntime.create();

rt.preloadModule(name: 'parser', source: '''
  export async function parseArticles(html) {
    const dom = await import('dom');
    const articles = JSON.parse(dom.querySelectorAll(html, '.article'));
    return articles.map(a => ({ title: a.text, html: a.innerHtml }));
  }
''');

final result = rt.eval(code: '''
  (async () => {
    const { parseArticles } = await import('parser');
    const html = '<div class="article">Hello</div><div class="article">World</div>';
    return JSON.stringify(await parseArticles(html));
  })()
''');

print(result.asStringSync);  // [{"title":"Hello","html":"Hello"},...]

rt.dispose();
```

### 示例 6：Dart↔JS 方法调用（JsCallbackHandler）

```dart
final engine = JsEngine.create(
  builtins: JsBuiltinOptions.web(),
);
final handler = JsCallbackHandler(engine);

// 注册 Dart 方法（同步，立刻响应）
handler.register('sum', (args) {
  return JsValue.integer(args[0].asIntegerSync + args[1].asIntegerSync);
});

handler.register('postMessage', (args) {
  print('[${args[0].asStringSync}] ${args[1]}');
  return JsValue.none();
});

// JS 调用 —— sum 立刻返回，无需 await
handler.eval('''
  postMessage("info", JSON.stringify({
    total: sum(10, 20)
  }));
''');

engine.close();
```

---

## 迁移指南（旧 API → 新 API）

| 旧 API | 新 API |
|--------|--------|
| `JsRuntime.create(maxMemoryBytes: n)` | `JsRuntime.create(options: JsRuntimeOptions(memoryLimit: n))` 或 `JsRuntime.createLegacy(maxMemoryBytes: n)` |
| `evalJs(code)` → `String` | `eval(code)` → `JsValue` 或 `evalJs(code)` → `String`（兼容） |
| `preloadModule(name, source)` | 不变 |
| `memoryUsage()` → `BigInt` | 不变 |
| `releaseMemory()` | 不变（或 `runGc()`） |
| `totalMemoryUsage()` → `BigInt` | 不变 |
| `dispose()` | 不变（现返回 `void`，失败抛 `JsError`） |

---

## 架构说明

### 线程模型

```
Dart Main Isolate
    │
    ├── #[frb(sync)]  ← 所有方法在同一线程执行
    │
    ↓
thread_local! { RUNTIMES: HashMap<u64, RuntimeState> }
    │
    ├── context: boa_engine::Context (Rc, !Send)
    ├── max_memory: u64
    ├── estimated_memory: u64
    └── ...
```

### 模块结构

```
rust/src/api/          （FRB 公开 API）
├── js_value.rs        JsValue 枚举 + Boa 互转
├── js_error.rs        JsError 枚举 + 错误码 + 分类
├── runtime.rs         JsRuntime 低层 API + 向后兼容方法
├── engine.rs          JsEngine 高层封装（含 CompletedCall + 回调注册）
├── repl.rs            JsRepl 交互式 REPL
├── eval_options.rs    JsEvalOptions
├── builtin_options.rs JsBuiltinOptions + 预设
├── module.rs          JsModule
└── hello.rs           示例函数

rust/src/js_runtime/   （内部实现，不暴露给 Dart）
└── internal.rs        RuntimeState, RUNTIMES, init_context, create_native_fn
```

### 运行时创建流程

```
JsRuntime.create(options)
    │
    ├── init_context(max_memory)
    │   ├── Context::builder().module_loader(MapModuleLoader).build()
    │   ├── 按 JsBuiltinOptions 注册扩展
    │   │   ├── ConsoleExtension（console: true）
    │   │   └── FetchExtension（fetch: true）
    │   ├── register_dom_module()（始终注册）
    │   │   ├── querySelectorAll   (html, css) → JSON
    │   │   ├── querySelector      (html, css) → JSON|null
    │   │   ├── getElementsByTagName (html, tag) → JSON
    │   │   └── getElementById     (html, id)  → JSON|null
    │   └── boa_icu_provider::buffer()（Intl API 数据）
    │
    └── 存入 thread_local! RUNTIMES
```

### GC 模型

```
run_gc()
    │
    ├── boa_gc::force_collect()    ← 标记-清除完整 GC
    ├── context.clear_kept_objects() ← 清理 WeakRef 目标
    └── 重置 estimated_memory / total_code_bytes
```

---

## 限制与注意事项

| 限制 | 说明 |
|------|------|
| **同步阻塞** | 所有方法 `#[frb(sync)]`，长时间执行的 JS 会阻塞 Dart UI |
| **无顶层 await** | `eval()` 以 script 模式执行，顶层 `await` 需包裹在 async IIFE 中 |
| **静态 import** | 仅支持动态 `import()`，不支持顶层 `import ... from` |
| **DOM API** | 仅查询（read-only），无 `createElement`、事件系统等 |
| **CORS** | `fetch` 无跨域限制（原生 HTTP 客户端） |
| **WebSocket** | 不支持 |
| **localStorage** | 不支持（可通过预加载模块自行实现） |
| **内存泄漏** | 未调用 `dispose()`/`close()` 会导致运行时泄漏 |
| **内存估算** | `memoryUsage()` 为估算值（代码+模块字节），精确值用 `totalMemoryUsage()` |

---

## 依赖

### Rust

| Crate | 版本 | 用途 |
|-------|------|------|
| [boa_ast](https://crates.io/crates/boa_ast) | 0.21.1 | ECMAScript AST 类型（Script、Module、Position、Span） |
| [boa_engine](https://crates.io/crates/boa_engine) | 0.21.1 | ECMAScript 引擎（features: `intl_bundled`） |
| [boa_gc](https://crates.io/crates/boa_gc) | 0.21.1 | 垃圾回收（`force_collect()`） |
| [boa_icu_provider](https://crates.io/crates/boa_icu_provider) | 0.21.1 | ICU4X 国际化数据（通过 `intl_bundled` 引入） |
| [boa_interner](https://crates.io/crates/boa_interner) | 0.21.1 | 字符串内部化（解析器符号表） |
| [boa_macros](https://crates.io/crates/boa_macros) | 0.21.1 | 派生宏（Trace、Finalize、TryFromJs、utf16!） |
| [boa_parser](https://crates.io/crates/boa_parser) | 0.21.1 | JS 解析器（语法校验、REPL 多行检测） |
| [boa_runtime](https://crates.io/crates/boa_runtime) | 0.21.1 | Web API 扩展（console, fetch） |
| [boa_string](https://crates.io/crates/boa_string) | 0.21.1 | ECMAScript 字符串类型（JsString） |
| [scraper](https://crates.io/crates/scraper) | 0.22 | HTML5 解析器 + CSS 选择器 |
| [serde](https://crates.io/crates/serde) + [serde_json](https://crates.io/crates/serde_json) | 1 | JSON 序列化 |
| [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) | 2.13.0-beta.1 | Dart ↔ Rust FFI |

### Dart

| Package | 用途 |
|---------|------|
| [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) | FRB 运行时 |
| [freezed_annotation](https://pub.dev/packages/freezed_annotation) | JsValue/JsError sealed class |
| [freezed](https://pub.dev/packages/freezed)（dev）| 代码生成 |
| [build_runner](https://pub.dev/packages/build_runner)（dev）| FRB 代码生成 |

# JsRuntime API 文档

`JsRuntime` 是一个嵌入式 JavaScript 运行时，基于 [Boa](https://github.com/boa-dev/boa)（纯 Rust 实现的 ECMAScript 引擎），通过 `flutter_rust_bridge` 同步调用，支持完整的 ES 语法及常用 Web API。

## 环境
1、添加ohos-openssl
```bash
# ~/.ohos/
gh repo clone ohos-rs/ohos-openssl
```

2、~/.cargo/config.toml中配置
```toml
AARCH64_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/arm64-v8a/"
ARMV7_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/armeabi-v7a/"
X86_64_UNKNOWN_LINUX_OHOS_OPENSSL_DIR="~/.ohos/ohos-openssl/prelude/x86_64/"
```


## Dart API

### 创建运行时

```dart
import 'package:t_lib/lib.dart';

// 不限制内存
final rt = JsRuntime.create();

// 设置 50MB 内存上限
final rt = JsRuntime.create(
  maxMemoryBytes: BigInt.from(50 * 1024 * 1024),
);
```

每次调用 `create()` 会创建一个**独立的 JS 上下文**，全局状态（变量、函数、模块注册表）完全隔离。

> 设置 `maxMemoryBytes` 后，`evalJs()` 执行前后会检查进程内存是否超限，超限返回错误。

### 执行 JS 代码

```dart
String result = rt.evalJs(code: '''
  var x = 1;
  var y = 2;
  x + y
''');
print(result); // "3"
```

- **返回值**：JS 表达式的求值结果转为字符串
- **状态保持**：同一运行时内的多次调用共享全局变量和函数定义
- **同步执行**：方法标记 `#[frb(sync)]`，在 Dart 主 isolate 线程上运行
- **async/await 支持**：如果 JS 代码返回 Promise，自动调用 `await_blocking()` 等待完成

### 预加载 ES 模块

```dart
rt.preloadModule(
  name: 'math-utils',   // import 时使用的 specifier
  source: '''
export function add(a, b) { return a + b; }
export const VERSION = '1.0';
''',
);
```

JS 端通过动态 `import()` 导入：

```js
const math = await import('math-utils');
math.add(3, 4);         // 7
math.VERSION;           // "1.0"
```

> **注意**：当前仅支持动态 `import()`，不支持顶层静态 `import` 语句。因为 `eval_js` 以 script 模式执行——静态 import 需要 module 模式。

### 内存管理

#### 查询内存用量

```dart
// 当前运行时的估算内存（累计执行的代码 + 加载的模块源码字节数）
BigInt used = rt.memoryUsage();

// 整个进程的物理内存 RSS（仅 Linux / HarmonyOS 支持，其他平台返回 0）
BigInt total = JsRuntime.totalMemoryUsage();
```

#### 释放内存（不销毁运行时）

```dart
rt.releaseMemory();  // 清理 WeakRef 保持的对象，重置代码估算值
```

#### 内存超限处理

```dart
final rt = JsRuntime.create(
  maxMemoryBytes: BigInt.from(50 * 1024 * 1024), // 50MB
);

final result = rt.evalJs(code: someScript);
// 若进程内存超限，返回错误：
// "Memory limit exceeded: used 52428800 bytes, limit 52428800 bytes."
```

| 方法 | 说明 |
|---|---|
| `rt.memoryUsage()` | 估算值 = 累计执行的代码字节 + 预加载模块字节 |
| `JsRuntime.totalMemoryUsage()` | 进程 RSS 物理内存（Linux/HarmonyOS 读取 `/proc/self/status`） |
| `rt.releaseMemory()` | 调用 `clear_kept_objects()` + 重置代码估算值 |
| `create(maxMemoryBytes:)` | 设置内存上限，eval 前后检查，超限返回错误 |

### 销毁运行时

```dart
rt.dispose();  // 释放所有资源，调用后句柄不再可用
```

---

## 内置 Web API

以下 API 在 `createRuntime()` 时自动注册，JS 代码可直接使用：

### console

| 方法 | 说明 |
|---|---|
| `console.log(...args)` | 标准输出 |
| `console.error(...args)` | 标准错误 |
| `console.warn(...args)` | 标准输出（前缀 `[JS Warn]`） |
| `console.info(...args)` | 标准输出 |
| `console.debug(...args)` | 标准输出 |
| `console.trace(...args)` | 带调用栈的标准输出 |

### fetch

```js
var r = await fetch('https://example.com/api');
var data = await r.json();    // or r.text(), r.blob(), r.arrayBuffer()
console.log(r.status, r.ok);
```

- 使用 `reqwest` **同步阻塞** HTTP 客户端
- 支持 `GET`、`POST`、自定义 headers、body 等完整 Request API
- 返回标准 `Response` 对象

### 定时器

```js
setTimeout(() => console.log('later'), 1000);
setInterval(() => console.log('tick'), 500);
clearTimeout(id);
clearInterval(id);
```

> 定时器在 `eval_js` 的 `await_blocking()` 循环中可能被多次触发，取决于 JS 执行时长。

### 其他

| API | 说明 |
|---|---|
| `TextEncoder` / `TextDecoder` | 文本编解码 |
| `URL` / `URLSearchParams` | URL 解析与构造 |
| `queueMicrotask(fn)` | 微任务队列 |
| `structuredClone(obj)` | 深拷贝 |
| `atob()` / `btoa()` | Base64 编解码 |

---

## DOM 解析模块

`"dom"` 模块在运行时创建时自动注册，提供 HTML 解析和 CSS 选择器能力。底层使用 [scraper](https://crates.io/crates/scraper)（Servo 的 html5ever 解析器）。

### 导入

```js
const dom = await import('dom');
```

### API

所有查询函数接收两个参数：`(html: string, selector: string)`，返回 **JSON 字符串**。使用 `JSON.parse()` 解析即可得到原生 JS 对象。

#### `querySelectorAll(html, css)` → JSON 数组

```js
const html = '<div class="foo"><p>A</p><p>B</p></div>';
const elements = JSON.parse(dom.querySelectorAll(html, '.foo p'));
console.log(elements.length);           // 2
console.log(elements[0].tagName);       // "p"
console.log(elements[0].text);          // "A"
console.log(elements[0].innerHtml);     // "A"
```

#### `querySelector(html, css)` → JSON 对象 或 null

```js
const html = '<div id="x"><span>hello</span></div>';
const el = JSON.parse(dom.querySelector(html, '#x span'));
if (el) {
    console.log(el.tagName);   // "span"
    console.log(el.text);      // "hello"
}
```

支持所有标准 CSS 选择器：元素、类、ID、属性、后代、子代、兄弟、伪类等。

#### `getElementsByTagName(html, tag)` → JSON 数组

```js
const html = '<div><p>A</p><p>B</p><span>C</span></div>';
const pTags = JSON.parse(dom.getElementsByTagName(html, 'p'));
console.log(pTags.length);  // 2
```

#### `getElementById(html, id)` → JSON 对象 或 null

```js
const html = '<div id="main"><p>content</p></div>';
const el = JSON.parse(dom.getElementById(html, 'main'));
console.log(el.tagName);  // "div"
```

### ElementData 结构

```ts
interface ElementData {
  tagName: string;                  // 标签名（小写），如 "div"
  text: string;                     // 文本内容（所有子文本合并）
  innerHtml: string;                // 内部 HTML
  id: string;                       // id 属性值，无则为 ""
  classes: string[];                // class 列表
  attrs: [string, string][];       // 所有属性键值对数组
}
```

---

## 完整示例

### 示例 1：基础使用 + 内存管理

```dart
// 创建运行时，设置 100MB 上限
final rt = JsRuntime.create(
  maxMemoryBytes: BigInt.from(100 * 1024 * 1024),
);

// 查看初始内存
print('内存: ${rt.memoryUsage()} bytes');     // 估算值
print('进程: ${JsRuntime.totalMemoryUsage()} bytes'); // RSS

// 执行同步 JS
rt.evalJs(code: 'var counter = 0;');
rt.evalJs(code: 'counter++; counter');       // "1"
rt.evalJs(code: 'counter++; counter');       // "2"

// 查看内存增长
print('内存: ${rt.memoryUsage()} bytes');

// 手动释放（保留运行时）
rt.releaseMemory();
print('释放后: ${rt.memoryUsage()} bytes');

// 完全销毁
rt.dispose();
```

### 示例 2：预加载模块 + 数学计算

```dart
final rt = JsRuntime.create();

rt.preloadModule(
  name: 'geometry',
  source: '''
export function circleArea(r) { return Math.PI * r * r; }
export function sphereVolume(r) { return (4/3) * Math.PI * r * r * r; }
''',
);

final result = rt.evalJs(code: '''
  (async () => {
    const geo = await import('geometry');
    return JSON.stringify({
      area: geo.circleArea(5),
      volume: geo.sphereVolume(5)
    });
  })()
''');
print(result); // {"area":78.5398...,"volume":523.5987...}

rt.dispose();
```

### 示例 3：HTML 解析

```dart
final rt = JsRuntime.create();

final result = rt.evalJs(code: '''
  (async () => {
    const dom = await import('dom');

    const html = \`<html>
      <head><title>Test Page</title></head>
      <body>
        <div class="article">
          <h1 id="title">Hello World</h1>
          <p class="content">First paragraph</p>
          <p class="content">Second paragraph</p>
          <a href="/more">Read more</a>
        </div>
      </body>
    </html>\`;

    // 提取标题
    const title = JSON.parse(dom.querySelector(html, '#title'));
    console.log('Title:', title.text);

    // 提取所有段落
    const paragraphs = JSON.parse(dom.querySelectorAll(html, 'p.content'));
    console.log('Paragraphs:', paragraphs.length);

    // 提取链接
    const link = JSON.parse(dom.querySelector(html, 'a[href]'));
    console.log('Link:', link.attrs.find(a => a[0] === 'href')[1]);

    return JSON.stringify({
      title: title.text,
      paragraphCount: paragraphs.length,
      paragraphs: paragraphs.map(p => p.text)
    });
  })()
''');
// {"title":"Hello World","paragraphCount":2,"paragraphs":["First paragraph","Second paragraph"]}

rt.dispose();
```

### 示例 4：fetch + DOM 解析

```dart
final rt = JsRuntime.create();

final result = rt.evalJs(code: '''
  (async () => {
    const dom = await import('dom');

    // 获取网页 HTML
    const r = await fetch('https://example.com');
    const html = await r.text();

    // 解析标题
    const titleEl = JSON.parse(dom.querySelector(html, 'title'));
    const h1El = JSON.parse(dom.querySelector(html, 'h1'));

    return JSON.stringify({
      title: titleEl?.text ?? 'N/A',
      h1: h1El?.text ?? 'N/A',
      status: r.status
    });
  })()
''');
print(result);

rt.dispose();
```

---

## 架构说明

### 线程模型

```
Dart Main Isolate
    │
    ├── rt.create()          ← #[frb(sync)]
    ├── rt.evalJs()          ← #[frb(sync)]
    ├── rt.preloadModule()   ← #[frb(sync)]
    ├── rt.memoryUsage()     ← #[frb(sync)]
    ├── rt.releaseMemory()   ← #[frb(sync)]
    ├── totalMemoryUsage()   ← #[frb(sync)] (static)
    └── rt.dispose()         ← #[frb(sync)]
         │
         ↓ (同一线程)
    thread_local! { RUNTIMES: HashMap<u64, RuntimeState> }
         │
         ├── context: boa_engine::Context
         ├── max_memory: u64
         ├── estimated_memory: u64
         └── ...
```

- `Context` 使用 `Rc`（非 `Send`），所有调用必须通过 `#[frb(sync)]` 在同一线程执行
- `thread_local! + RefCell` 存储 `RuntimeState`（含 Context + 内存追踪数据）
- 内存估算 = 累计执行代码字节数 + 预加载模块源码字节数
- 进程 RSS 通过 `/proc/self/status`（Linux/HarmonyOS）获取

### 运行时创建

```
JsRuntime.create(max_memory_bytes?)
    │
    ├── 创建 RuntimeState { max_memory, estimated_memory: 0, ... }
    │
    ├── Context::builder()
    │   .module_loader(MapModuleLoader)  ← 内存模块映射表
    │   .build()
    │
    ├── boa_runtime::register()
    │   ├── ConsoleExtension(DefaultLogger)
    │   ├── FetchExtension(BlockingReqwestFetcher)
    │   ├── TimeoutExtension        (自动)
    │   ├── EncodingExtension       (自动)
    │   ├── MicrotaskExtension      (自动)
    │   ├── StructuredCloneExtension (自动)
    │   └── UrlExtension            (自动)
    │
    └── register_dom_module()
        └── Synthetic Module "dom"
            ├── querySelectorAll()
            ├── querySelector()
            ├── getElementsByTagName()
            └── getElementById()
```

---

## 限制与注意事项

| 限制 | 说明 |
|---|---|
| **同步阻塞** | `evalJs()` 是同步的，长时间执行的 JS（如大循环、慢速 fetch）会阻塞 Dart UI 线程 |
| **无顶层 await** | `eval_js` 以 script 模式执行，顶层 `await` 语法不允许；使用 IIFE 包裹 |
| **静态 import** | 仅支持动态 `import()`，不支持顶层 `import ... from`
| **DOM API** | 仅提供查询能力（read-only），没有 `document.createElement`、事件系统等完整 DOM |
| **CORS** | `fetch` 无跨域限制（原生 HTTP 客户端） |
| **WebSocket** | 不支持 |
| **localStorage** | 不支持（可通过 Dart 端自行实现并预加载为模块） |
| **内存泄漏** | 未调用 `dispose()` 会导致运行时泄漏；`releaseMemory()` 可部分缓解，但不能替代 `dispose()` |
| **内存估算** | `memoryUsage()` 为估算值（代码+模块字节），不是实际堆内存；精确值用 `totalMemoryUsage()` |

---

## 依赖

- [boa_engine](https://crates.io/crates/boa_engine) 0.21.1 — ECMAScript 引擎
- [boa_runtime](https://crates.io/crates/boa_runtime) 0.21.1 — Web API 扩展（console, fetch, url 等）
- [scraper](https://crates.io/crates/scraper) 0.22 — HTML5 解析器 + CSS 选择器
- [serde](https://crates.io/crates/serde) + [serde_json](https://crates.io/crates/serde_json) — JSON 序列化（DOM 结果输出）
- [flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/) 2.13.0-beta.1 — Dart ↔ Rust FFI

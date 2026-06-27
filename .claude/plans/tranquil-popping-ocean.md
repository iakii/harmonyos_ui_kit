# 修复 response.url 返回重定向后最终 URL

## 问题

`meitule.cjs` 的 `search()` 发 POST 搜索请求 → 服务器 302 重定向到结果页。但 `BlockingReqwestFetcher` 传给 `JsResponse` 的是原始请求 URL（`request.uri()`），而非重定向后的 `resp.url()`。因此 `res.url` 永远是 `/e/search`，拿不到结果页地址。

## 改动（3 个 Rust 文件 + 1 个 JS 文件）

### 1. 新建 `packages/js_runtime/rust/src/js_runtime/fetcher.rs`

自定义 `RedirectAwareFetcher`，代码从 `BlockingReqwestFetcher` 复制，唯一区别：

```rust
// 原代码: JsString::from(url)          ← url = request.uri()（原始 URL）
// 新代码: JsString::from(final_url)     ← final_url = resp.url()（重定向后最终 URL）
let final_url = resp.url().to_string();
// ... 必须在 resp.bytes() 消费之前调用
.map(|inner| JsResponse::basic(JsString::from(final_url), inner))
```

### 2. 修改 `packages/js_runtime/rust/src/js_runtime/mod.rs`

添加一行：`pub(crate) mod fetcher;`

### 3. 修改 `packages/js_runtime/rust/src/js_runtime/internal.rs`

两行改动：import 替换 + `register_web_apis` 中替换 Fetcher

### 4. 修改 `assets/js/meitule.cjs` 的 `search()`

改为 POST 表单 + 使用 `res.url`：

```javascript
async search(keyword, page = 1) {
    const url = `${this.info.website}/e/search/`;
    const body = `name=news&show=title&tempid=1&keyboard=${encodeURIComponent(keyword)}`;
    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: body,
    });
    console.log("search 重定向后 URL：", res.url);
    return this.fetchGallery(res.url, page);
}
```

### Cargo.toml 无需改动

`reqwest`、`http` 已是 `boa_runtime` 的传递依赖，在 `Cargo.lock` 中存在，可直接使用。

## 验证

```bash
cd packages/js_runtime/rust && cargo build
```
编译通过 → 运行 App → 对 meitule 执行搜索 → 日志确认 `res.url` 为重定向后的结果页 URL

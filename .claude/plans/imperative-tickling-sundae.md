# 美图乐详情页一次性加载5条数据并返回 nextPageUrl

## 上下文

用户选中 `assets/js/meitule.cjs` 第 152-181 行的代码，要求修改 `_parse` 方法实现：
- 一次加载 5 条网页数据（当前每次只加载 1 条）
- 返回 `nextPageUrl` 供 Dart 层分页累加器使用

### 当前行为

- `fetchDetails(url)` → `_parse(url, page=1)`
- `_parse` 只请求一个 URL，提取 1 个 item（从 `div.content > a[href][title]` + `img[src]`）
- 返回 `{ list: [1 item], totalPage: N, current: page }`
- **无 `nextPageUrl`**，导致 Dart 侧 `DetailPageAccumulator` 回退到 `_buildNextPageUrl`（`?page=N` 查询参数模式，对美图乐无效）

### URL 分页模式

- 第 1 页：`.../article/123456.html`
- 第 N 页（N>1）：`.../article/123456_N.html`
- 已注释的旧代码（184-199 行）确认此模式：`url.replace(".html", `_${index}.html`)`

### Dart 侧已就绪

- `GalleryDetail.fromJson` 已支持 `nextPageUrl` 字段
- `DetailPageAccumulator.loadNext()` 优先使用 `nextPageUrl`，回退到 `_buildNextPageUrl`
- 一旦 JS 返回 `nextPageUrl`，Dart 侧分页即可正常工作

## 修改方案

### 只改一个文件：`assets/js/meitule.cjs`

**1. 修改 `fetchDetails` (144-148 行)**

当 `page` 参数未传递时，从 URL 中自动提取页码：

```javascript
async fetchDetails(url, page) {
    // 如果未指定 page，尝试从 URL 中提取（如 xxx_6.html → page=6）
    if (page == null) {
        const match = url.match(/_(\d+)\.html$/);
        page = match ? parseInt(match[1], 10) : 1;
    }
    const items = await this._parse(url, page);
    return JSON.stringify(items);
}
```

**2. 重构 `_parse` 方法 (150-203 行)**

核心逻辑：
- 首先加载当前页 `url`，提取 1 个 item，获取 `totalPages`
- 循环加载后续 4 页（`page+1` 到 `page+4`），每页提取 1 个 item
- 若下一页超过总页数，提前终止
- 若加载完 5 条后还有更多页，计算 `nextPageUrl` 指向第 `page+5` 页
- 返回 `{ list, totalPage, current, nextPageUrl }`

具体改动：
- 将原来提取单个 item 的代码包装为加载 **当前页** 的逻辑
- 新增循环加载后续 4 页（参照已注释的 184-199 行代码）
- 构造 `nextPageUrl`：若 `page + 5 <= totalPages`，生成 `url.replace(".html", `_${page + 5}.html`)`
- 返回结构增加 `nextPageUrl` 字段

## 验证方式

1. 运行 `flutter analyze` 确认无静态分析错误（JS 文件不影响 Dart 分析）
2. 在应用中打开美图乐某个详情页，观察：
   - 首次加载应显示 5 条数据
   - 向下滚动触底时应触发 `loadNext`，加载下一批 5 条
   - 直到所有页加载完毕，`hasMore` 变为 false
3. 检查日志确认 `nextPageUrl` 被正确传递

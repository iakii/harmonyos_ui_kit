function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}

/**
 *  @description: 美图乐妹子
 *  @website: https://www.meitula.org
 *   class BaseClient {
 *      info:{
 *        type: string;
 *        version: string;
 *        website: string;
 *        name: string;
 *        menus: { label: string; path: string }[];
 *      }
 *     async fetchGallery(url: string, page: number): Promise<string> ;
 *     async fetchDetails(url: string): Promise<string> ;
 *   }
 *
 */
class Client {
  info = {
    type: "photo",
    version: "1.0.0",
    icon: "https://www.meitula.org/favicon.ico",
    website: "https://www.meitula.org",
    name: "美图乐妹子",
    menus: [
      { label: "首页", path: "" },
      { label: "最新", path: "/i" },
      { label: "周榜", path: "/week" },
      { label: "月榜", path: "/month" },
      { label: "年榜", path: "/year" },
      { label: "最热", path: "/top" },
      { label: "模特", path: "/model" },
      // { label: "机构", path: "/page/jigou" },
      { label: "标签", path: "/photo" },
    ],
  };

  get pluginInfo() {
    return JSON.stringify(this.info);
  }

  async fetchGallery(url, page = 1) {
    if (page != 1) {
      url = `${url}/index_${page}.html`;
    }
    console.log("getPage 请求的url：", url);
    const base = this.info.website;
    try {
      const html = await fetch(url).then((response) => response.text());
      const dom = await import("dom");
      const isModelPage = url.includes("/model");
      if (isModelPage) {
        // 模特列表页：遍历 ul > li，从每个 li 中提取信息
        const lis = JSON.parse(dom.querySelectorAll(html, "div.list ul li"));
        const results = lis.map((li) => {
          const aRaw = dom.querySelector(li.innerHtml, "a.list-img");
          const aTag = aRaw !== null ? JSON.parse(aRaw) : null;
          const imgRaw = dom.querySelector(li.innerHtml, "img");
          const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
          const spanRaw = dom.querySelector(li.innerHtml, "div.list-num span");
          const spanTag = spanRaw !== null ? JSON.parse(spanRaw) : null;

          const href = aTag?.attrs?.find((a) => a[0] === "href")?.[1] || "";
          const src =
            imgTag?.attrs?.find((a) => a[0] === "data-src")?.[1] || "";
          const alt = imgTag?.attrs?.find((a) => a[0] === "alt")?.[1] || "";
          const count = spanTag?.text || "";

          return {
            link: base + href,
            cover: base + src,
            title: alt ? `${alt} (${count})` : count,
            to: "gallery",
          };
        });
        const totalPages = await this._parsePageSize(html, dom);
        return JSON.stringify({
          list: results,
          totalPage: totalPages,
          current: page,
        });
      }

      // 遍历每个 a.list-img，从其 innerHtml 中提取 img 信息
      const links = JSON.parse(dom.querySelectorAll(html, "li.list-item"));

      const results = links
        .map((linkEl) => {
          const imgRaw = dom.querySelector(linkEl.innerHtml, "img");
          const numRaw = dom.querySelector(linkEl.innerHtml, "div.list-num");
          const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
          const cover =
            imgTag?.attrs?.find((a) => a[0] === "data-src")?.[1] || "";
          const tagsRaw =
            JSON.parse(dom.querySelectorAll(linkEl.innerHtml, "dd")) ?? [];
          const hrefRaw =
            JSON.parse(dom.querySelector(linkEl.innerHtml, "a.list-img")) ||
            null;

          const tags = tagsRaw
            .map((tagEl) => {
              const a =
                JSON.parse(dom.querySelector(tagEl?.innerHtml, "a")) || null;
              const href = a?.attrs?.find((a) => a[0] === "href")?.[1] || "";
              return {
                href: base + href,
                title: a?.text || "",
                to: "gallery",
              };
            })
            .filter(Boolean);

          const href = hrefRaw?.attrs?.find((a) => a[0] === "href")?.[1] || "";
          console.log("href:", href);
          if (href.startsWith("http") && href.indexOf(base) === -1) return null;
          const result = {
            link: href.startsWith("https") ? href : base + href,
            cover: cover,
            title: `【${JSON.parse(numRaw).text}】${imgTag?.attrs?.find((a) => a[0] === "alt")?.[1] || ""}`,
            tags,
          };
          // console.log("result:", result);
          return result;
        })
        .filter(Boolean);
      const totalPages = await this._parsePageSize(html, dom);
      return JSON.stringify({
        list: results,
        totalPage: totalPages,
        current: page,
      });
    } catch (error) {
      console.log("获取页面失败：", error);
    }
  }

  async fetchDetails(url) {
    // 如果没有指定 page，尝试从 URL 中提取页码（如 xxx_6.html → page=6）
    const match = url.match(/_(\d+)\.html$/);
    let page = match ? parseInt(match[1], 10) : 1;
    const items = await this._parse(url, page);
    return JSON.stringify(items);
  }

  async _parse(url, page = 1) {
    const dom = await import("dom");

    // 归一化基础 URL，去掉可能存在的页码后缀（如 _6.html → .html）
    const baseUrl = url.replace(/_\d+\.html$/, '.html');

    // 构造当前页 URL 并获取内容
    const currentUrl = page === 1 ? baseUrl : baseUrl.replace(".html", `_${page}.html`);
    const html = await fetch(currentUrl).then((response) => response.text());

    // 从当前页提取 1 条 item
    const items = [];
    const item = this._extractItemFromHtml(html, dom);
    if (item) items.push(item);

    // 获取总页数（只需从当前页解析一次即可）
    const totalPages = await this._parsePageSize(html, dom);

    // 再加载后续 4 页，凑足 5 条一次性返回
    for (let i = page + 1; i < page + 5; i++) {
      if (i > totalPages) break;
      const pageUrl = baseUrl.replace(".html", `_${i}.html`);
      await waitTime();
      const pageHtml = await fetch(pageUrl).then((r) => r.text());
      const pageItem = this._extractItemFromHtml(pageHtml, dom);
      if (pageItem) items.push(pageItem);
    }

    const result = { list: items, current: page + 5 };
    // 如果还有更多页，构造 nextPageUrl
    if (page + 5 <= totalPages) {
      result.nextPageUrl = baseUrl.replace(".html", `_${page + 5}.html`);
    }
    console.log(result);
    return result;
  }

  /** 从 HTML 中提取一条 item（cover / href / title） */
  _extractItemFromHtml(html, dom) {
    const contentRaw = dom.querySelector(html, "div.content");
    const contentDiv = contentRaw !== null ? JSON.parse(contentRaw) : null;
    if (!contentDiv) return null;

    const aRaw = dom.querySelector(contentDiv.innerHtml, "a[href][title]");
    const aTag = aRaw !== null ? JSON.parse(aRaw) : null;
    const href = aTag?.attrs?.find((a) => a[0] === "href")?.[1] || null;
    const title = aTag?.attrs?.find((a) => a[0] === "title")?.[1] || null;

    const imgRaw = dom.querySelector(contentDiv.innerHtml, "img[src]");
    const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
    const src = imgTag?.attrs?.find((a) => a[0] === "src")?.[1] || null;

    // 至少有一个有效字段才返回
    return src || href ? { cover: src, href, title } : null;
  }

  async _parsePageSize(html, dom) {
    // 用 DOM 查询分页链接替代正则
    const pageLinks = JSON.parse(
      dom.querySelectorAll(html, "li.page-item a.page-link"),
    );
    const numbers = pageLinks
      .filter((el) => el.text === "尾页")
      .map((el) => {
        const href = el.attrs.find((a) => a[0] === "href")?.[1] || "";
        const match = href.includes("/tags/")
          ? href.match(/(\d+)\.html/)
          : href.match(/_(\d+)\.html/);
        return match ? parseInt(match[1], 10) : null;
      })
      .filter((n) => n !== null);
    if (pageLinks.length > 0 && numbers.length === 0) {
      const lastPageLink = pageLinks[pageLinks.length - 1];
      if (lastPageLink) {
        return parseInt(lastPageLink.text, 10);
      }
    }
    return numbers.length > 0 ? Math.max(...numbers) : 1;
  }
}
const client = new Client();
export default client;

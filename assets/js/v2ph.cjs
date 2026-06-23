function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}

/**
 *  @description: v2ph
 *  @website: https://www.v2ph.org
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
    icon: "https://www.v2ph.com/img/favicon.svg",
    website: "https://www.v2ph.com",
    name: "微图坊",
    menus: [
      { label: "首页", path: "" },
      // 分类菜单
      { label: "性感美女", path: "/category/sexy-girls" },
      { label: "女神", path: "/category/nvshen" },
      { label: "短发", path: "/category/short-hair" },
      { label: "清纯", path: "/category/pure" },
      { label: "内衣美女", path: "/category/underwear-beauty" },
      { label: "杂志", path: "/category/magazine" },
      { label: "嫩模", path: "/category/glamour-models" },
      { label: "美腿", path: "/category/beautiful-legs" },
      { label: "日本少女", path: "/category/japanese-girls" },
      { label: "极品", path: "/category/best-quality" },
      { label: "外拍", path: "/category/outside" },
      { label: "比基尼", path: "/category/bikini-girls" },
      // 国家/地区菜单
      { label: "中国大陆", path: "/country/china" },
      { label: "日本", path: "/country/japan" },
      { label: "韩国", path: "/country/south-korea" },
      { label: "台湾", path: "/country/taiwan" },
      { label: "泰国", path: "/country/thailand" },
      { label: "欧美", path: "/country/europe" },
      { label: "写真机构", path: "/company/" },
    ],

    "headers": {
      "accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
      "accept-encoding": "gzip, deflate, br, zstd",
      "accept-language": "zh-CN,zh;q=0.9",
      "cache-control": "no-cache",
      "pragma": "no-cache",
      "priority": "i",
      "referer": "https://www.v2ph.com/",
      "sec-ch-ua": "\"Google Chrome\";v=\"149\", \"Chromium\";v=\"149\", \"Not)A;Brand\";v=\"24\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"Windows\"",
      "sec-fetch-dest": "image",
      "sec-fetch-mode": "no-cors",
      "sec-fetch-site": "same-site",
      "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
    }
  };

  get pluginInfo() {
    return JSON.stringify(this.info);
  }

  async fetchGallery(url, page = 1) {
    // if (page != 1) {
    //   url = `${url}/index_${page}.html`;
    // }
    console.log("getPage 请求的url：", url);
    const base = this.info.website;
    try {
      const html = await fetch(url).then((response) => response.text());
      const dom = await import("dom");
      const links = JSON.parse(dom.querySelectorAll(html, "div.card"));
      const results = links.map((linkEl) => {
        console.log("linkEl:", linkEl);
        const imgRaw = dom.querySelector(linkEl.innerHtml, "img");
        const a = JSON.parse(dom.querySelector(linkEl.innerHtml, "a")) || null;
        const numRaw = JSON.parse(dom.querySelector(linkEl.innerHtml, "div.album-photos span")) || null;
        const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
        const cover = (imgTag?.attrs?.find((a) => a[0] === "src")?.[1] || "");
        const title = (imgTag?.attrs?.find((a) => a[0] === "alt")?.[1] || "");
        const href = a.attrs?.find((a) => a[0] === "href")?.[1] || "";
        if (href.startsWith('/actor/')) {
          return;
        }
        const tagsRaw = JSON.parse(dom.querySelectorAll(linkEl.innerHtml, "dd")) ?? [];
        const tags = tagsRaw.map((tagEl) => {
          const a = JSON.parse(dom.querySelector(tagEl?.innerHtml, "a")) || null;
          const href = a?.attrs?.find((a) => a[0] === "href")?.[1] || "";
          // if (href.startsWith('http')) {
          //   return;
          // }
          return {
            href: base + href,
            title: a?.text || "",
            to: "gallery",
          };

        }).filter(Boolean);
        const result = {
          link: href.startsWith('https') ? href : base + href,
          cover,
          title: numRaw ? `【${numRaw.text}】${title}` : title,
          tags,
        };
        return result;
      }).filter(Boolean);
      console.log("results：", results);
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

  async fetchDetails(url, parsePage = true) {
    // 创建 URL 对象
    const items = await this._parse(url, parsePage);
    return JSON.stringify({
      list: items,
      current: 1,
    });
  }

  async _parse(url, parsePage = true) {
    const dom = await import("dom");
    const html = await fetch(url).then((response) => response.text());
    // 获取 div.content 容器，再从其 innerHtml 中查询子元素
    const contentRaw = dom.querySelector(html, "div.photos-list");
    const contentDiv = contentRaw !== null ? JSON.parse(contentRaw) : null;
    if (contentDiv) {
      const aRaw = JSON.parse(dom.querySelectorAll(contentDiv.innerHtml, "img") || null);
      return aRaw.map((a) => {
        const cover = a.attrs?.find((attr) => attr[0] === "src")?.[1] || "";
        const alt = a.attrs?.find((attr) => attr[0] === "alt")?.[1] || "";
        return {
          cover,
          href: "",
          title: alt,
        }
      });
    }
    return [];
  }

  async _parsePageSize(html, dom) {
    // 用 DOM 查询分页链接替代正则
    const pageLinks = JSON.parse(
      dom.querySelectorAll(html, "li.page-item a.page-link"),
    );
    const numbers = pageLinks.filter((el) => el.text === '尾页')
      .map((el) => {
        const href = el.attrs.find((a) => a[0] === "href")?.[1] || "";
        const match = href.includes('/tags/') ? href.match(/(\d+)\.html/) : href.match(/_(\d+)\.html/);
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

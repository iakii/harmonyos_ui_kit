function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}

/**
 *  @description: kaizty
 *  @website: https://www.kaizty.com
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
    website: "https://www.kaizty.com",
    icon: "https://www.kaizty.com/favicon.ico",
    name: "Kaizty",
    menus: [
      { label: "🏚️ 首页", path: "" },
      { label: "🔥 最热", path: "/hot" },
      { label: "👻 Cosplay", path: "/category/%5BCosplay%5D" },
      { label: "🎀 网路收集系列", path: "/category/【网路收集系列】" },
      { label: "📦 网路收集", path: "/category/【网路收集】" },
      { label: "🎬 JVID", path: "/category/%5BJVID%5D" },
      { label: "🍬 萌甜物语系列", path: "/category/【萌甜物语系列】" },
      { label: "📸 陆模私拍系列", path: "/category/【陆模私拍系列】" },
      { label: "🐦 推特美女", path: "/category/【推特美女】" },
      { label: "🫧 清凉写真", path: "/category/【清凉写真】" },
      { label: "🌸 台模系列", path: "/category/【台模系列】" },
      { label: "🏮 国模系列", path: "/category/【国模系列】" },
      { label: "✨ 高丝女子系列", path: "/category/【高丝女子系列】" },
      { label: "🌪️ 风之领域", path: "/category/【风之领域】" },
    ],
  };

  get pluginInfo() {
    return JSON.stringify(this.info);
  }
  async fetchGallery(url, page = 1) {
    if (page != 1) {
      url = `${url}/?page=${page}`;
    }
    console.log("getPage 请求的url：", url);
    const base = this.info.website;
    try {
      const html = await fetch(url).then((response) => response.text());
      const dom = await import("dom");
      console.log('请求到数据', html.length)
      // 遍历每个 a.list-img，从其 innerHtml 中提取 img 信息
      const links = JSON.parse(dom.querySelectorAll(html, "div.thumb-view"));
      const results = links.map((linkEl) => {
        const imgRaw = dom.querySelector(linkEl.innerHtml, "img.xld");
        console.log(0, imgRaw, linkEl)
        const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
        const cover = (imgTag?.attrs?.find((a) => a[0] === "src")?.[1] || "");

        const href = JSON.parse(dom.querySelector(linkEl.innerHtml, 'a.denomination'))
        return {
          link: base + (href.attrs.find((a) => a[0] === "href")?.[1] || ""),
          cover: cover,
          title: imgTag?.attrs?.find((a) => a[0] === "alt")?.[1] || "",
        };
      });

      console.log(333, results)
      // const totalPages = await this._parsePageSize(html, dom);
      return JSON.stringify({
        list: results,
        totalPage: Number.MAX_VALUE,
        current: page,
      });
    } catch (error) {
      console.log("获取页面失败：", error);
    }
  }

  async fetchDetails(url, parsePage = true) {
    // 创建 URL 对象
    const dom = await import("dom");
    const html = await fetch(url).then((response) => response.text());
    const contentme = JSON.parse(dom.querySelector(html, 'div.contentme'))
    const image = JSON.parse(dom.querySelectorAll(contentme.innerHtml, 'img'))
    const list = image.map(img => {
      return {
        cover: img.attrs.find((a) => a[0] === "src")?.[1],
        href: "",
        title: "",
      }
    })
    const next = JSON.parse(dom.querySelectorAll(html, 'a.page-numbers')).find((el) => el.text === 'Next >')
    const href = next?.attrs.find((a) => a[0] === "href")?.[1] || null;
    const result = {
      list,
    };
    if (href) {
      result["nextPageUrl"] = this.info.website + href;
    }
    // console.log('result', result, url)
    return JSON.stringify(result);
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

    return numbers.length > 0 ? Math.max(...numbers) : 1;
  }
}
const client = new Client();
export default client;

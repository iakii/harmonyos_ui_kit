function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}

/**
 *  @description: sexygirl
 *  @website: https://www.sexygirl.com
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
    website: "https://sexygirl.cc",
    icon: "https://sexygirl.cc/favicon.ico",
    name: "性感女孩",
    menus: [
      { label: "最新", path: "/zh/photo/" },
      { label: "AI", path: "/zh/ai_picture/" },
      { label: "Cartoon", path: "/zh/cartoon/" },
      { label: "自拍", path: "/zh/selfie/" },
      { label: "图集", path: "/zh/album/" },
      { label: "视频", path: "/zh/video/" },
      { label: "发现", path: "/zh/discover/index.html" },
      // { label: "标签", path: "/photo" },
    ],
  };

  async _request(url) {
    return fetch(url, {
      method: 'GET', // 或 'POST', 'PUT' 等
      origin: this.info.website, // 设置请求的源
      headers: {
        // 'User-Agent':
        //   'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
        // 'Referer': this.info.website,
        // 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        // // "Accept-encoding": "gzip, deflate",
        // // 'Accept-Language': 'zh-CN,zh;q=0.9',
        // "Host": this.info.website.replace(/^https?:\/\//, ''),

        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        // 'Accept-Encoding': 'gzip, deflate',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1'
      },
      credentials: 'same-origin' // 关键：允许跨域请求携带Cookie等凭据
    }).then(r => r.text());
  }



  get pluginInfo() {
    return JSON.stringify(this.info);
  }
  async fetchGallery(url, page = 1) {
    // if (page != 1) {
    //   url = `${url}/?page=${page}`;
    // }
    console.log("getPage 请求的url：", url);
    const base = this.info.website;
    try {
      const html = await this._request(url);
      const dom = await import("dom");
      console.log('请求到数据', html)
      // 遍历每个 a.list-img，从其 innerHtml 中提取 img 信息
      const links = JSON.parse(dom.querySelectorAll(html, "div.card"));
      console.log(111, links)
      const results = links.map((linkEl) => {
        const imgRaw = dom.querySelector(linkEl.innerHtml, "img");
        console.log(0, imgRaw, linkEl)
        const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
        const cover = (imgTag?.attrs?.find((a) => a[0] === "src")?.[1] || "");

        const href = JSON.parse(dom.querySelector(linkEl.innerHtml, 'a'))
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

    console.log(`请求${url} 获得数据`, html.length)

    const contentme = JSON.parse(dom.querySelector(html, 'div.contentme'))

    console.log(111, contentme)

    const image = JSON.parse(dom.querySelectorAll(contentme.innerHtml, 'img'))

    const list = image.map(img => {

      console.log(222, JSON.stringify(img))

      return {
        cover: img.attrs.find((a) => a[0] === "src")?.[1],
        href: "",
        title: "",
      }
    })

    // console.log(222, image)

    return JSON.stringify({
      list,
      current: 1,
    });
  }

  async _parse(url, parsePage = true) {
    const dom = await import("dom");
    const html = await fetch(url).then((response) => response.text());
    // 获取 div.content 容器，再从其 innerHtml 中查询子元素
    const contentRaw = dom.querySelector(html, "div.content");
    const contentDiv = contentRaw !== null ? JSON.parse(contentRaw) : null;

    let href = null;
    let title = null;
    let src = null;

    if (contentDiv) {
      const aRaw = dom.querySelector(contentDiv.innerHtml, "a[href][title]");
      const aTag = aRaw !== null ? JSON.parse(aRaw) : null;
      if (aTag) {
        href = aTag.attrs.find((a) => a[0] === "href")?.[1] || null;
        title = aTag.attrs.find((a) => a[0] === "title")?.[1] || null;
      }

      const imgRaw = dom.querySelector(contentDiv.innerHtml, "img[src]");
      const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
      if (imgTag) {
        src = imgTag.attrs.find((a) => a[0] === "src")?.[1] || null;
      }
    }

    const items = [
      {
        cover: src,
        href,
        title,
      },
    ];

    // 获取总页数
    if (parsePage) {
      const totalPages = await this._parsePageSize(html, dom);
      for (let index = 2; index < +totalPages; index++) {
        console.log("获取第几页：", index, "总页数：", totalPages);
        const pageUrl = `${url.replace(".html", `_${index}.html`)}`;
        await waitTime();
        const result = await this._parse(pageUrl, false);
        items.push(...result);
        if (items.length % 5 == 0) {
          postMessage(
            "sendChannelDetails",
            JSON.stringify({
              list: items,
              current: index,
            }),
          );
        }
      }
    }

    return items;
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

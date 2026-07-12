

class Client {
  info = {
    type: "photo",
    version: "1.0.0",
    "website": "http://www.swmzt.com",
    "name": "丝袜妹子图",
    "icon": "http://www.swmzt.com/favicon.ico",
    "menus": [
      { "label": "首页", "path": "" },
      { "label": "性感美女", "path": "/si/tuwa/1_1.html" },
      { "label": "日韩套图", "path": "/si/tuwa/2_1.html" },
      { "label": "内衣丝袜", "path": "/si/tuwa/9_1.html" },
      { "label": "萌妹萝莉", "path": "/si/tuwa/11_1.html" },
      { "label": "精品套图", "path": "/si/tuwa/18_1.html" },
      { "label": "高清套图", "path": "/si/tuwa/24_1.html" },
      { "label": "无圣光", "path": "/si/tuwa/25_1.html" },
      { "label": "标签", "path": "/photo/" },
    ],

  }

  get pluginInfo() {
    return JSON.stringify(this.info);
  }

  async search(keywords, page = 1) {
    // http://www.symzt.com/chis/$text/1.html
    const keyword = await toPinYin(keywords ?? '')
    console.log("search 请求的keyword：", keyword, keywords);
    const url = `${this.info.website}/chis/${keyword}/${page}.html`;
    return this.fetchGallery(url, page);
  }

  async fetchGallery(path, page = 1) {

    const isHomePage = path === this.info.website;
    let url = path;

    if (!isHomePage) {
      url = `${path.replace(/\/(\d+_)?\d+\.html$/, `/$1${page}.html`)}`
    }
    // console.log("getPage 请求的url：", { isHomePage, path, url });

    const html = await this._request(url);

    const dom = await import("dom");
    let listLi;
    if (isHomePage) listLi = JSON.parse(dom.querySelectorAll(html, "div.img li"));
    else listLi = JSON.parse(dom.querySelectorAll(html, "div ul li"));

    const list = listLi.map((li) => {
      let a, img;
      try {
        a = JSON.parse(dom.querySelector(li.innerHtml, "a"));
      } catch {
        a = null;
      }
      try {
        img = JSON.parse(dom.querySelector(li.innerHtml, "img"));
      } catch {
        img = null;
      }
      const href = a?.attrs?.find((a) => a[0] === "href")?.[1] || "";
      const cover = img?.attrs?.find((a) => a[0] === "lazy-src" || a[0] == 'src')?.[1] || "";
      const title = li.text || "";
      return {
        link: `${this.info.website}${href}`,
        cover: cover,
        title: title,
      };
    });
    const totalPages = await this._parsePageSize(html, dom);
    return JSON.stringify({
      list: list,
      totalPage: totalPages,
      currentPage: page,
    });
  }


  async _request(url) {
    const enc = await import('encoding');
    return fetch(url, {
      method: 'GET', // 或 'POST', 'PUT' 等
      origin: this.info.website, // 设置请求的源
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
        'Referer': this.info.website,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        // "Accept-encoding": "gzip, deflate",
        'Accept-Language': 'zh-CN,zh;q=0.9',
        "Host": this.info.website.replace(/^https?:\/\//, ''),
      },
      credentials: 'same-origin' // 关键：允许跨域请求携带Cookie等凭据
    }).then(r => r.bytes()).then(response => {
      return enc.decode(response, 'gbk');
    });
  }


  async fetchDetails(url, page = 1) {
    if (page != 1) url = `${url.replace(".html", `_${page}.html`)}`;
    console.log("getDetail 请求的url：", url);
    const html = await this._request(url);
    const dom = await import("dom");

    const slide = JSON.parse(dom.querySelectorAll(html, "div.slide"));
    console.log("slide:", slide);

    const list = slide.map(x => {
      console.log("slide x:", JSON.stringify(x))
      const img = JSON.parse(dom.querySelector(x.innerHtml, "img"));
      // console.log("slide img:", img);
      const src = img?.attrs?.find((a) => a[0] === "data_src")?.[1] || "";
      const a = JSON.parse(dom.querySelector(x.innerHtml, "a"));
      const href = a?.attrs?.find((a) => a[0] === "href")?.[1] || "";
      const title = img?.attrs?.find((a) => a[0] === "alt")?.[1] || "";
      return {
        cover: src,
        href,
        title,
      }
    })


    const result = { list }
    const pageLinks = JSON.parse(dom.querySelectorAll(html, "div.pagelist a"));
    // 取最后一个
    if (pageLinks.length > 0) {
      pageLinks.map(x => {
        parseInt(x.text, 10) && (result.totalPage = Math.max(result.totalPage || 0, parseInt(x.text, 10)))
      })
    }
    return JSON.stringify(result);
  }

  async _parsePageSize(html, dom) {
    const pageLinks = JSON.parse(dom.querySelectorAll(html, "div.pagelist a"));
    // 取最后一个
    const page = pageLinks.length > 0 ? pageLinks[pageLinks.length - 1] : "1";
    const href = page?.attrs?.find((a) => a[0] === "href")?.[1] || "";
    const regExp = /_(\d+)\.html/;
    const match = href.match(regExp);
    const pageNum = match ? parseInt(match[1], 10) : null;
    return pageNum || 1;
  }
}


export default new Client();
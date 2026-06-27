// http://mh.jdtaotu.com/mh/hmlist.asp?page=70 漫画

class Client {
  info = {
    type: "photo",
    version: "1.0.0",
    "website": "https://taotu.org",
    "name": "套图网",
    "icon": "https://taotu.org/favicon.ico",
    "menus": [
      { "label": "首页", "path": "/" },
      { "label": "热门", "path": "/popular/" },
      { "label": "推荐", "path": "/recommend/" },
      { "label": "足控", "path": "/tag/足控/" },
      { "label": "美腿写真", "path": "/s?q=美腿写真" },
      { "label": "漫画", "path": "/s?q=漫画" },
      { "label": "蕾丝", "path": "/tag/蕾丝/" },
      { "label": "秀人网", "path": "/publisher/秀人网/" },
    ],
    "headers": {
      "accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
      "accept-encoding": "gzip, deflate, br, zstd",
      "accept-language": "zh-CN,zh;q=0.9",
      "cache-control": "no-cache",
      "pragma": "no-cache",
      "priority": "i",
      "referer": "https://meirentu.cc/",
      "sec-ch-ua": "\"Google Chrome\";v=\"149\", \"Chromium\";v=\"149\", \"Not)A;Brand\";v=\"24\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"Windows\"",
      "sec-fetch-dest": "image",
      "sec-fetch-mode": "no-cors",
      "sec-fetch-site": "cross-site",
      "sec-fetch-storage-access": "active",
      "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36"
    }

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

    let url = path;
    // page-1.html
    if (page != 1) url = `${path}page-${page}.html`;


    const html = await this._request(url);

    console.log("getPage 请求的url：", url, html);

    const dom = await import("dom");
    let listLi = JSON.parse(dom.querySelectorAll(html, "div#MainContent_piclist  div"));
    const list = listLi.map((div) => {
      const a = JSON.parse(dom.querySelector(div.innerHtml, "a"));
      let img = JSON.parse(dom.querySelector(a.innerHtml, "img"));
      const href = a?.attrs?.find((a) => a[0] === "href")?.[1] || "";
      const cover = img?.attrs?.find((a) => a[0] === "src")?.[1] || "";
      const title = JSON.parse(dom.querySelector(div.innerHtml, "h2"))?.text || "";

      return {
        link: `${this.info.website}${href}`,
        cover: `${cover}`,
        title: title.trim(),
      };
    });
    // const pageLinks = JSON.parse(dom.querySelectorAll(html, "div.pagelist a"));
    // // 取最后一个
    // if (pageLinks.length > 0) {
    //   pageLinks.map(x => {
    //     parseInt(x.text, 10) && (result.totalPage = Math.max(result.totalPage || 0, parseInt(x.text, 10)))
    //   })
    // }

    const result = { list: list, totalPage: Number.MAX_VALUE, current: page };

    console.log('getPage result', JSON.stringify(result), url)
    return JSON.stringify(result);
  }


  async _request(url) {
    return fetch(url, {
      method: 'GET', // 或 'POST', 'PUT' 等
      origin: this.info.website, // 设置请求的源
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
        'Referer': this.info.website,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'zh-CN,zh;q=0.9',
        "Host": this.info.website.replace(/^https?:\/\//, ''),
      },
      credentials: 'same-origin' // 关键：允许跨域请求携带Cookie等凭据
    }).then(r => r.text())
  }

  async fetchIntro(url, page = 1) {
    console.log("getIntro 请求的url：", url);

    const html = await this._request(url);
    const dom = await import("dom");
    const base = this.info.website;
    const _domQ = (h, s) => { try { return JSON.parse(dom.querySelector(h, s)) } catch { return null } };
    const _domQA = (h, s) => { try { return JSON.parse(dom.querySelectorAll(h, s)) } catch { return [] } };

    // ====== 1. 提取漫画标题 (h2) ======
    const title = _domQ(html, "h2")?.text || "";

    // ====== 2. 提取漫画基本信息 (manga-detail-card) ======
    let cover = "", author = "", category = "", status = "";
    const tags = [];

    const urlpath = url.includes('mhrm') ? 'mhrm' : 'mh';

    const card = _domQ(html, "div.manga-detail-card");
    if (card) {
      // 封面
      const img = _domQ(card.innerHtml, "div.cover img");
      cover = img?.attrs?.find(a => a[0] === "src")?.[1] || "";

      // info 段落：作者/分类/状态
      const infoPs = _domQA(card.innerHtml, "div.info p");
      for (const p of infoPs) {
        const text = p.text?.trim() || "";
        if (text.includes("作者")) {
          author = text.replace(/^.*作者[：:]\s*/, "").trim();
        } else if (text.includes("分类")) {
          category = text.replace(/^.*分类[：:]\s*/, "").trim();
        } else if (text.includes("状态")) {
          status = text.replace(/^.*状态[：:]\s*/, "").trim();
        }
      }

      // 标签
      const tagDiv = _domQ(card.innerHtml, "div.tag");
      if (tagDiv) {
        const tagAs = _domQA(tagDiv.innerHtml, "a");
        for (const a of tagAs) {
          const href = a?.attrs?.find(x => x[0] === "href")?.[1] || "";
          tags.push({
            title: a?.text?.trim() || "",
            href: `${base}/${urlpath}/${href}`,
            to: "gallery",
          });
        }
      }
    }

    // ====== 3. 提取简介 (jianjie) ======
    const descP = _domQ(html, "div.jianjie p");
    const description = descP?.text?.trim() || "";

    // ====== 4. 提取章节列表 (chapter-list) ======
    const chapterAs = _domQA(html, "div.chapter-list a");
    const list = chapterAs.map(a => ({
      title: a?.text?.trim() || "",
      href: `${base}/${urlpath}/${a?.attrs?.find(x => x[0] === "href")?.[1] || ""}`,
      to: "page",
    }));

    const result = { title, cover: `${base}${cover}`, author, category, status, description, tags, list };
    // console.log('getIntro result', JSON.stringify(result), url);
    return JSON.stringify(result);
  }

  async fetchDetails(url, page = 1) {
    const html = await this._request(url);
    const dom = await import("dom");
    const links = JSON.parse(dom.querySelectorAll(html, "div#MainContent_piclist a"));
    const base = this.info.website;

    try {
      const results = links.map((img) => {
        const cover = (img?.attrs?.find((a) => a[0] === "href")?.[1] || "");
        return {
          cover: cover,
          title: img?.attrs?.find((a) => a[0] === "alt")?.[1] || "",
        };
      })
      const result = { list: results };
      const response = JSON.stringify(result)
      console.log('getDetail result', response, url)
      return response;
    } catch (error) {
      console.log("获取页面失败：", error);
    }

    return JSON.stringify({ list: [] });
  }
}


export default new Client();
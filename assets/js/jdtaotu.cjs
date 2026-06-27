// http://mh.jdtaotu.com/mh/hmlist.asp?page=70 漫画

class Client {
  info = {
    type: "photo",
    version: "1.0.0",
    "website": "http://mh.jdtaotu.com",
    "name": "漫画jdtaotu",
    "icon": "http://mh.jdtaotu.com/favicon.ico",
    "menus": [
      { "label": "首页", "path": "/mh/hmlist.asp" },
      { "label": "日漫", "path": "/mhrm/rmlist.asp" },
      { "label": "连载中", "path": "/mh/hmlist.asp?state=连载中" },
      { "label": "已完结", "path": "/mh/hmlist.asp?state=已完结" },
    ],
  }

  get pluginInfo() {
    return JSON.stringify(this.info);
  }

  async search(keyword, page = 1) {
    const url = `${this.info.website}/mh/hmso.asp?keyword=${encodeURIComponent(keyword)}&page=${page}`;
    return await this.fetchGallery(url, 1);
  }

  async fetchGallery(path, page = 1) {

    let url = path;
    if (page != 1) url = `${path}?page=${page}`;

    const urlpath = path.includes('mhrm') ? 'mhrm' : 'mh';

    const html = await this._request(url);
    const dom = await import("dom");
    let listLi = JSON.parse(dom.querySelectorAll(html, "div.manga-item"));
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
      const cover = img?.attrs?.find((a) => a[0] === "src")?.[1] || "";
      const title = a.text || "";
      return {
        link: `${this.info.website}/${urlpath}/${href}`,
        cover: `${this.info.website}${cover}`,
        to: urlpath === 'mhrm' ? 'page' : "intro",
        title: title.trim(),
      };
    });
    const result = { list: list, currentPage: page }

    const pageLinks = JSON.parse(dom.querySelectorAll(html, "div.pagination a"));
    // 取最后一个
    if (pageLinks.length > 0) {
      pageLinks.map(x => {
        parseInt(x.text, 10) && (result.totalPage = Math.max(result.totalPage || 0, parseInt(x.text, 10)))
      })
    }
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
        // "Accept-encoding": "gzip, deflate",
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
    console.log("getDetail 请求的url：", url);
    const html = await this._request(url);
    const dom = await import("dom");
    // 日漫 image-gallery
    const isrm = url.includes('mhrm');
    const links = JSON.parse(dom.querySelectorAll(html, isrm ? 'div.image-gallery img' : "div.manga-image-section img"));
    const base = this.info.website;
    // console.log('getDetail links', links, url)

    try {
      const results = links.map((img) => {
        console.log(0, img)
        const cover = (img?.attrs?.find((a) => a[0] === "data-src")?.[1] || "");
        return {
          cover: base + cover,
          title: img?.attrs?.find((a) => a[0] === "alt")?.[1] || "",
        };
      })

      const response = JSON.stringify({ list: results })
      // console.log('getDetail result', response, url)
      return response;
    } catch (error) {
      console.log("获取页面失败：", error);
    }

    return JSON.stringify({ list: [] });
  }
}


export default new Client();
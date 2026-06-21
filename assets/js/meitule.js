
function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}


class Client {

  _pluginInfo = {
    type: "photo",
    version: "1.0.0",
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
      { label: "机构", path: "/page/jigou" },
      { label: "标签", path: "/photo" },
    ],
  }
  get pluginInfo() {
    return JSON.stringify(this._pluginInfo);
  }

  getOriginFromUrl(url) {
    const match = url.match(/^(https?:\/\/[^/]+)/);
    return match ? match[1] : null;
  }

  async getPage(url, page = 1) {
    if (page != 1) {
      url = `${url}/index_${page}.html`
    }

    console.log("getPage 请求的url：", url);

    const parsedUrl = this._pluginInfo.website;

    try {
      const html = await fetch(url).then((response) => response.text());
      const dom = await import('dom');
      const isModelPage = url.includes('/model');
      if (isModelPage) {
        // 模特列表页：提取 a.list-img 中的 img 标签的 data-src 和 alt
        const links = JSON.parse(dom.querySelectorAll(html, 'div.list ul li a.list-img'));
        const imgs = JSON.parse(dom.querySelectorAll(html, 'div.list ul li a.list-img img'));
        const titles = JSON.parse(dom.querySelectorAll(html, 'div.list ul li div.list-num span'));
        console.log("模特列表页 - titles：", titles);
        const results = [];
        for (let i = 0; i < links.length; i++) {
          const linkEl = links[i];
          const imgEl = imgs[i];
          const count = titles[i]?.text || '';
          const href = linkEl.attrs.find(a => a[0] === 'href')?.[1] || '';
          results.push({
            link: parsedUrl + href,
            cover: this._pluginInfo.website + imgEl?.attrs?.find(a => a[0] === 'data-src')?.[1] || '',
            title: (imgEl?.attrs?.find(a => a[0] === 'alt')?.[1] || '') + ` (${count})`,
            to: "gallery"
          });
        }
        console.log("获取到的模特数量：", results);
        const totalPages = await this.getPhotosPageSize(html);
        console.log("获取到的总页数：", totalPages);
        return JSON.stringify({
          list: results,
          totalPage: totalPages,
          current: page,

        });
      }

      // 用 DOM 解析替代正则：分别查询 a 标签和内部 img 标签，索引一一对应
      const links = JSON.parse(dom.querySelectorAll(html, 'a.list-img'));
      const imgs = JSON.parse(dom.querySelectorAll(html, 'a.list-img img'));
      const results = [];
      for (let i = 0; i < links.length; i++) {
        const linkEl = links[i];
        const imgEl = imgs[i];
        const href = linkEl.attrs.find(a => a[0] === 'href')?.[1] || '';
        results.push({
          link: parsedUrl + href,
          cover: imgEl?.attrs?.find(a => a[0] === 'data-src')?.[1] || '',
          title: imgEl?.attrs?.find(a => a[0] === 'alt')?.[1] || '',
        });
      }
      const totalPages = await this.getPhotosPageSize(html);
      console.log("获取到的页数：", totalPages);
      // console.log("获取数据：", results);
      return JSON.stringify({
        list: results,
        totalPage: totalPages,
        current: page,
      });

    } catch (error) {
      console.log("获取页面失败：", error);
    }
  }

  async getDetails(url, parsePage = true) {
    // 创建 URL 对象
    const items = await this._parse(url, parsePage);
    return JSON.stringify({
      list: items,
      current: 1,
    });
  }


  async _parse(url, parsePage = true) {
    const html = await fetch(url).then((response) => response.text());
    // const parsedUrl = getOriginFromUrl( url );
    console.log("是否获取页数：", parsePage);

    const dom = await import('dom');

    // 获取 div.content 容器，再从其 innerHtml 中查询子元素
    const contentRaw = dom.querySelector(html, 'div.content');
    const contentDiv = contentRaw !== null ? JSON.parse(contentRaw) : null;

    let href = null;
    let title = null;
    let src = null;

    if (contentDiv) {
      const aRaw = dom.querySelector(contentDiv.innerHtml, 'a[href][title]');
      const aTag = aRaw !== null ? JSON.parse(aRaw) : null;
      if (aTag) {
        href = aTag.attrs.find(a => a[0] === 'href')?.[1] || null;
        title = aTag.attrs.find(a => a[0] === 'title')?.[1] || null;
      }


      const imgRaw = dom.querySelector(contentDiv.innerHtml, 'img[src]');
      const imgTag = imgRaw !== null ? JSON.parse(imgRaw) : null;
      if (imgTag) {
        src = imgTag.attrs.find(a => a[0] === 'src')?.[1] || null;
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
      const totalPages = await this.getPhotosPageSize(html);
      for (let index = 2; index < +totalPages; index++) {
        console.log("获取第几页：", index, "总页数：", totalPages);
        const pageUrl = `${url.replace(".html", `_${index}.html`)}`;
        await waitTime();
        const result = await this._parse(pageUrl, false);
        items.push(...result);

        console.log("当前获取到的数量：", items.length, "当前页数：", index, "总页数：", totalPages, "当前页url：", pageUrl, items.length % 5 == 0 ? "发送数据" : "不发送数据");
        if (items.length % 5 == 0) {
          console.log("发送数据：", items.length);
          await postMessage('sendChannelDetails', JSON.stringify({
            list: items,
            current: index,
          }));
        }
      }
    }

    console.log("最终获取到的数量：", items.length);
    // postMessage('stopLoading');
    return items;
  }




  async getPhotosPageSize(html) {
    const dom = await import('dom');

    // 用 DOM 查询分页链接替代正则
    const pageLinks = JSON.parse(dom.querySelectorAll(html, 'li.page-item a.page-link'));

    const numbers = pageLinks
      .map(el => {
        const href = el.attrs.find(a => a[0] === 'href')?.[1] || '';
        const match = href.match(/_(\d+)\.html/);
        return match ? parseInt(match[1], 10) : null;
      })
      .filter(n => n !== null);

    return numbers.length > 0 ? Math.max(...numbers) : 1;
  }

}
const client = new Client();
export default client;
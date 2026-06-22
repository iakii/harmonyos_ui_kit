class Client {
  _pluginInfo = {
    type: "video",
    version: "1.0.0",
    website: "https://tyys2.com",
    name: "统一影视",
    menus: [
      { label: "首页", path: "" },
      { label: "电视剧", path: "/index.php/vod/type/id/1/page" },
      { label: "电影", path: "/index.php/vod/type/id/2/page" },
      { label: "动漫", path: "/index.php/vod/type/id/3/page" },
      { label: "综艺", path: "/index.php/vod/type/id/4/page" },
      { label: "体育赛事", path: "/index.php/vod/type/id/5/page" },
      { label: "短剧", path: "/index.php/vod/type/id/41/page" },
    ],
  };
  get pluginInfo() {
    return JSON.stringify(this._pluginInfo);
  }

  getOriginFromUrl(url) {
    const match = url.match(/^(https?:\/\/[^/]+)/);
    return match ? match[1] : null;
  }

  async _parseHomePage() {
    const html = await fetch(this._pluginInfo.website).then(res => res.text());
    // 提取单个视频项的正则表达式
    const videoItemRegex = /<div class="public-list-box[\s\S]*?<a[^>]*?href="([^"]*?)"[^>]*?title="([^"]*?)"[^>]*?>[\s\S]*?<img[^>]*?data-src="([^"]*?)"[^>]*?>[\s\S]*?<div class="public-list-subtitle[^>]*?>([\s\S]*?)<\/div>/g;

    const videos = [];

    let match;
    while ((match = videoItemRegex.exec(html)) !== null) {
      videos.push({
        link: match[1].trim(),          // a标签的href
        title: match[2].trim(),         // title属性
        cover: match[3].trim(),         // data-src属性
        status: match[4].trim()         // 更新状态
      });
    }
    return JSON.stringify({
      totalCount: videos.length, current: 1, totalPage: 1,
      list: videos,
    })
  }


  async fetchGallery(url, page = 1) {
    const isHome = url === this._pluginInfo.website
    // 创建 URL 对象
    const origin = this._pluginInfo.website
    console.log("fetchGallery 请求的url：", url, "page:", page, "isHome:", isHome);
    if (isHome) return this._parseHomePage();
    else url = `${url}/${page}.html`

    const htmlStr = await fetch(url).then(res => res.text());


    const itemReg = /<div class="public-list-box public-pic-b">([\s\S]*?)<\/div>\s*<\/div>/g;

    const items = [];

    let match;

    while ((match = itemReg.exec(htmlStr)) !== null) {
      const block = match[1];

      // link
      const linkMatch = block.match(/<a[^>]*class="public-list-exp"[^>]*href="([^"]+)"/);
      const link = linkMatch ? linkMatch[1] : "";

      // 提取 cover
      const coverMatch = block.match(/<img[^>]+data-src="([^"]+)"/);
      const cover = coverMatch ? coverMatch[1] : "";

      // 提取 status
      const statusMatch = block.match(/<span[^>]*class="[^"]*public-list-prb[^"]*"[^>]*>([^<]*)<\/span>/);
      const status = statusMatch ? statusMatch[1].trim() : "";

      // 提取 title
      const titleMatch = block.match(/<a[^>]*class="[^"]*time-title[^"]*"[^>]*>([^<]*)<\/a>/);
      const title = titleMatch ? titleMatch[1].trim() : "";

      // 提取 desc
      const descMatch = block.match(/<div[^>]*class="[^"]*public-list-subtitle[^"]*"[^>]*>([\s\S]*?)<\/div>/);
      let desc = descMatch ? descMatch[1] : "";
      desc = desc.replace(/&nbsp;/g, ' ').replace(/<[^>]+>/g, '').replace(/^\s+|\s+$/g, '');
      items.push({ cover, status, title, desc, link: origin + link });
    }

    const tipMatch = htmlStr.match(/共(\d+)条数据,当前(\d+)\/(\d+)页/);
    const totalCount = tipMatch ? parseInt(tipMatch[1], 10) : 0;
    const current = tipMatch ? parseInt(tipMatch[2], 10) : 0;
    const totalPage = tipMatch ? parseInt(tipMatch[3], 10) : 0;

    function extractFilterList(html, filterName, type) {
      // 匹配 <span>类型</span> ... <ul>...</ul>
      const reg = new RegExp(`<span>${filterName}<\\/span>[\\s\\S]*?<ul[^>]*>([\\s\\S]*?)<\\/ul>`);
      const blockMatch = html.match(reg);
      if (!blockMatch) return [];

      const ulContent = blockMatch[1];
      // 匹配每个li
      const liReg = /<li[^>]*>\s*<a[^>]+href="([^"]+)"[^>]*>([^<]+)<\/a>/g;
      let m, list = [];
      while ((m = liReg.exec(ulContent)) !== null) {
        list.push({ label: m[2].trim(), key: `/class/${m[2].trim()}` });
      }
      return list;
    }

    return JSON.stringify({
      totalCount, current, totalPage,
      list: items,
      filter: {
        "排序": [
          { label: "最新", key: "/by/time" },
          { label: "最热", key: "/by/hits" },
          { label: "评分", key: "/by/score" },
        ],
        '类型': extractFilterList(htmlStr, '类型', 'class'),
        '地区': extractFilterList(htmlStr, '地区', 'area'),
        '年份': extractFilterList(htmlStr, '年份', 'year'),
        '语言': extractFilterList(htmlStr, '语言', 'lang'),
      }
    });
  }

  async fetchDetails(url) {

    console.log("getDetails", url);

    const htmlStr = await fetch(url).then(res => res.text());

    // 创建 URL 对象
    const origin = this.getOriginFromUrl(url);

    // 封面
    const coverMatch = htmlStr.match(/<div class="detail-pic">\s*<img[^>]+data-src="([^"]+)"/);
    const cover = coverMatch ? coverMatch[1] : "";

    // 名称
    const titleMatch = htmlStr.match(/<h3[^>]*class="slide-info-title[^"]*"[^>]*>([^<]*)<\/h3>/);
    const title = titleMatch ? titleMatch[1].trim() : "";

    // 状态
    const statusMatch = htmlStr.match(/<span[^>]*class="slide-info-remarks"[^>]*>(已完结|更新至[^<]*)<\/span>/);
    const status = statusMatch ? statusMatch[1].trim() : "";

    // 年份
    const yearMatch = htmlStr.match(/<span[^>]*class="slide-info-remarks"[^>]*>\s*<a[^>]*>(\d{4})<\/a>/);
    const year = yearMatch ? yearMatch[1] : "";

    // 地区
    const areaMatch = htmlStr.match(/<span[^>]*class="slide-info-remarks"[^>]*>\s*<a[^>]*>([^<]*大陆|香港|台湾|美国|日本|韩国|英国|法国|泰国|新加坡|马来西亚|印度|德国|意大利|加拿大|澳大利亚|其他)<\/a>/);
    const area = areaMatch ? areaMatch[1] : "";

    // 导演
    const directorMatch = htmlStr.match(/<strong[^>]*>导演 *:<\/strong>([\s\S]*?)<\/div>/);
    let director = "";
    if (directorMatch) {
      const aMatch = directorMatch[1].match(/<a[^>]*>([^<]+)<\/a>/);
      director = aMatch ? aMatch[1] : "";
    }

    // 演员
    const actorMatch = htmlStr.match(/<strong[^>]*>演员 *:<\/strong>([\s\S]*?)<\/div>/);
    let actors = [];
    if (actorMatch) {
      const aList = actorMatch[1].match(/<a[^>]*>([^<]+)<\/a>/g);
      if (aList) {
        actors = aList.map(a => a.replace(/<a[^>]*>|<\/a>/g, ''));
      }
    }

    // 类型
    const typeMatch = htmlStr.match(/<strong[^>]*>类型 *:<\/strong>([\s\S]*?)<\/div>/);
    let types = [];
    if (typeMatch) {
      const aList = typeMatch[1].match(/<a[^>]*>([^<]+)<\/a>/g);
      if (aList) {
        types = aList.map(a => a.replace(/<a[^>]*>|<\/a>/g, ''));
      }
    }

    // 简介
    const descMatch = htmlStr.match(/<div id="height_limit"[^>]*>([\s\S]*?)<\/div>/);
    let desc = descMatch ? descMatch[1] : "";
    desc = desc.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/^\s+|\s+$/g, '');

    // 评分
    const scoreMatch = htmlStr.match(/<div class="fraction">([\d.]+)<\/div>/);
    const score = scoreMatch ? scoreMatch[1] : "";


    // 匹配所有资源tab
    const tabReg = /<a[^>]*class="swiper-slide[^"]*"[^>]*>(?:<i[^>]*>.*?<\/i>)?&nbsp;([^<]*?)(?:<span[^>]*>[^<]*<\/span>)?<\/a>/g;
    let tabMatch, tabs = [];
    while ((tabMatch = tabReg.exec(htmlStr)) !== null) {
      tabs.push(tabMatch[1].replace(/（.*?）/, '').trim());
    }

    // 匹配所有分集ul
    const ulReg = /<ul class="anthology-list-play size">([\s\S]*?)<\/ul>/g;
    let ulMatch, allEpisodes = [];
    while ((ulMatch = ulReg.exec(htmlStr)) !== null) {
      const liReg = /<a[^>]*href="([^"]+)"[^>]*>([^<]+)<\/a>/g;
      let liMatch, episodes = [];
      while ((liMatch = liReg.exec(ulMatch[1])) !== null) {
        episodes.push({ name: liMatch[2].trim(), href: origin + liMatch[1] });
      }
      allEpisodes.push(episodes);
    }

    // 组合资源名称和分集
    let result = [];
    for (let i = 0; i < tabs.length; i++) {
      result.push({
        source: tabs[i],
        episodes: allEpisodes[i] || []
      });
    }

    const response = JSON.stringify({
      detail: {
        cover,
        title,
        director,
        actors,
        types,
        desc,
        score,
        status,
        year,
        area
      },
      source: result
    }, null, 4);
    return response;
  }

  getPhotosPageSize(html) {
    let totalPages = 1;

    // 正则表达式匹配尾页的 <a> 标签的 href 属性
    var regex = /<li class="page-item"><a class="page-link" href="([^"]+)"/g;

    // 查找所有匹配项
    let hrefs = [];
    var match;

    // 提取所有的 href 链接
    while ((match = regex.exec(html))) {
      hrefs.push(match[1]); // 提取 href 的完整值
    }

    // 正则表达式匹配 href 中的数字
    const numberRegex = /_(\d+)\.html/;
    // 从每个 href 中提取数字
    let numbers = hrefs
      .map((href) => {
        const numberMatch = href.match(numberRegex);
        return numberMatch ? numberMatch[1] : null; // 提取数字部分
      })
      .filter((num) => num !== null); // 过滤掉没有数字的项

    totalPages = numbers.length > 0 ? Math.max(...numbers) : 1;

    return totalPages;
  }

  async getPlayUrl(url) {

    const html = await fetch(url).then(res => res.text());

    const iframe = html.includes("iframe")

    console.log('iframe>', iframe);

    // 正则匹配 src 属性值
    const regex = /<iframe[^>]*src=["']([^"']+)["']/i;
    const match = html.match(regex);

    if (match && match[1]) {
      console.log("提取到的 src 地址：", match[1]);
    } else {
      console.log("未找到 src 地址");
    }
  }

}
const client = new Client();
export default client;
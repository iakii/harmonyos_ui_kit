
// import axios from "./axios.min";

// // sendMessage('someChannelName', JSON.stringify([1,2,3])

// function fetch ( url ) {
//   return axios
//     .get( url )
//     .then( ( response ) => {
//       return response.data;
//     } )
//     .catch( ( error ) => console.log( error ) );
// }


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
    website: "https://www.meitu001.cc/",
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
      url = `${url}index_${page}.html`
    }

    const parsedUrl = this._pluginInfo.website;

    try {
      const html = await fetch(url);
      // 定义正则
      var regex =
        /<a class="list-img" href="(.*?)">.*?<img .*?data-src="(.*?)".*?alt="(.*?)"/g;
      // 提取数据
      const results = [];
      var match;

      while ((match = regex.exec(html)) !== null) {
        results.push({
          link: parsedUrl + match[1], // href 链接
          cover: match[2], // img src 链接
          title: match[3], // alt 标题
        });
      }

      const totalPages = this.getPhotosPageSize(html);

      console.log("获取到的页数：", totalPages);
      console.log("获取数据：", results);

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

    const html = await fetch(url);

    // const parsedUrl = getOriginFromUrl( url );
    console.log("是否获取页数：", parsePage);
    // 提取 div class="content" 下的 a 标签 href 和 title
    const aTagMatch = html.match(
      /<div class="content">[\s\S]*?<a [^>]*href="([^"]+)"[^>]*title="([^"]+)"/
    );
    const href = aTagMatch ? aTagMatch[1] : null;
    const title = aTagMatch ? aTagMatch[2] : null;

    // 提取 div class="content" 下的 img 标签 src
    const imgTagMatch = html.match(
      /<div class="content">[\s\S]*?<img [^>]*src="([^"]+)"/
    );
    const src = imgTagMatch ? imgTagMatch[1] : null;

    const items = [
      {
        cover: src,
        href,
        title,
      },
    ];
    // 获取总页数
    const totalPages = this.getPhotosPageSize(html);
    if (parsePage) {
      for (let index = 2; index < +totalPages; index++) {
        console.log("获取第几页：", index, "总页数：", totalPages);
        const pageUrl = `${url.replace(".html", `_${index}.html`)}`;
        await waitTime();
        const result = await this._parse(pageUrl, false);
        items.push(...result);

        if (items.length % 5 == 0) {
          sendMessage('sendChannelDetails', JSON.stringify({ list: items }));
        }
      }
    }
    return items;
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

}
const client = new Client();
// export default client;

// console.log( client.pluginInfo )

// const html = await client.getPage( 'https://www.meitule.cc/i/', 2 )
// const html = await client.getDetails( 'https://www.meitule.cc/photo/73658.html', true )

// console.log( html );


// function fetch ( url, page ) {
//   return url + page;
// };
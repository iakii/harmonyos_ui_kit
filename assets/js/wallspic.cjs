function waitTime(duration = 300) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve();
    }, duration);
  });
}
class Client {
  info = {
    website: "https://wallspic.com/cn",
    name: "Wallspic",
    type: "photo",
    version: "1.0.0",
    menus: [
      { "path": "/", "label": "最新" },
      {
        "path": "/album/popular",
        "label": "人气",
      },
      {
        "path": "/topic/background_images",
        "label": "背景图片",
      },
      {
        "path": "/topic/4k_mobile_wallpapers",
        "label": "4k手机壁纸",
      },
      { "path": "/topic/8k_wallpapers", "label": "8k壁纸" },
      {
        "path": "/topic/windows_wallpapers",
        "label": "Windows壁纸",
      },
      {
        "path": "/topic/lock_screen_wallpapers",
        "label": "锁屏壁纸",
      },
      {
        "path": "/topic/wallpapers_for_boys",
        "label": "男孩壁纸",
      },
      {
        "path": "/topic/laptop_wallpapers",
        "label": "笔记本电脑壁纸",
      },
      {
        "path": "/topic/iphone_wallpapers",
        "label": "iPhone壁纸",
      },
      {
        "path": "/topic/screen_wallpapers",
        "label": "屏保壁纸",
      },
      { "path": "/topic/pc_wallpapers", "label": "电脑壁纸" },
      { "path": "/topic/4k_wallpapers", "label": "4k壁纸" },
      {
        "path": "/topic/ipad_wallpapers",
        "label": "iPad壁纸",
      },
      {
        "path": "/topic/full_hd_wallpapers",
        "label": "全高清壁纸",
      },
    ],
  }


  get pluginInfo() {
    return JSON.stringify(this.info);
  }

  /**
   *
   * @param {string} path 类型key
   * @param {number} page 分页默认1
   * @returns
   */
  async fetchGallery(path, page = 1) {
    console.log("getPage 请求的url：", `${path}?page=${page}`);
    const html = await fetch(`${path}?page=${page}`).then((response) => response.text());
    const dom = await import("dom");
    const scripts = JSON.parse(dom.querySelectorAll(html, "script"));


    let data = null;
    // 人气
    if (path.includes("/album/popular")) {
      data = JSON.parse(scripts[2].text);
      const totalPages = this._parsePageSize(scripts, dom);
      return JSON.stringify({
        list: data ? data.map(x => {
          return {
            link: x?.contentUrl,
            cover: x?.thumbnail?.contentUrl,
            title: x?.description,
            tags: [
              { title: "日期：" + x.datePublished, to: "none" },
            ]
          }
        }) : [],
        totalPage: totalPages,
        currentPage: page,
      })
    } else {
      const script = scripts.find(script => script.text.includes("window.mainAdaptiveGallery"));
      const regExp = /window\.mainAdaptiveGallery\s*=\s*(\{.*?\})\s*;/;
      const match = script.text.match(regExp);
      if (match && match[1]) {
        try {
          data = JSON.parse(match[1]);
        } catch (e) {
          console.error("JSON解析失败:", e);
        }
      }
    }

    const list = data ? data.list.map(x => {
      return {
        link: x?.original?.link,
        cover: x?.thumbnail?.link,
        title: x?.labels?.title,
        // tags,
        tags: [
          { title: `分辨率：${x.original.width}x${x.original.height}`, to: "none" },
        ]
      }
    }) || [] : [];
    const totalPages = this._parsePageSize(scripts, dom);
    return JSON.stringify({
      list,
      totalPage: totalPages,
      currentPage: page,
    })
  }

  _parsePageSize(scripts, dom) {

    const script = scripts.find(script => script.text.includes("window.mainGalleryTarget"));

    let data = null
    const regExp = /window\.mainGalleryTarget\s*=\s*(\{.*?\})\s*;/;
    const match = script.text.match(regExp);
    if (match && match[1]) {
      try {
        data = JSON.parse(match[1]);
      } catch (e) {
        console.error("JSON解析失败:", e);
      }
    }
    console.log("script:", data.pages);
    return data?.pages || 1;

  }

  async fetchDetails(url) {

    if (url.endsWith(".png") || url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".webp")) {
      return JSON.stringify({
        list: [
          {
            cover: url,
            href: url,
            title: "",
          }
        ],
        current: 1,
      });
    }

    console.log("getDetail 请求的url：", url);
    // await waitTime(300);
    const html = await fetch(url).then((response) => response.text());
    const dom = await import("dom");
    const scriptsEls = JSON.parse(dom.querySelector(html, "div.wallpaper__buttons"));
    const title = JSON.parse(dom.querySelector(html, "h1.wallpaper__title"));
    const aTag = JSON.parse(dom.querySelector(scriptsEls.innerHtml, "a.wallpaper__download"));
    const src =
      aTag?.attrs?.find((a) => a[0] === "href")?.[1] || "";
    const item = {
      cover: src,
      href: url,
      title: title?.text || "",
    };
    return JSON.stringify({
      list: [item],
      current: 1,
    });
  }

}

export default new Client();
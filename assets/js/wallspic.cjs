
const client = new Client();
class Client {
  info = {
    website: "https://wallspic.com/cn",
    name: "Wallspic",
    type: "photo",
    version: "1.0.0",
    menus: [
      { "path": "/", "label": "最新" },
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

  search(keywords) {
    return fetch(`https://wallspic.com/cn/api/v1/w/?q=${keywords}`).then((response) => response.json());
  }

  settings = {

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
  fetchGallery(path, page = 1) {
    return fetch(`https://wallspic.com/cn${path}?page=${page}`).then((response) => response.json());
  }
}

export default client;
class Client {
  info = {
    website: "https://wallhaven.cc/api/v1/w",
    name: "Wallhaven",
    type: "photo",
    version: "1.0.0",
    menus: [
      { label: "最新", path: "/date_added" },
      { label: "最热", path: "/toplist" },
      { label: "随机", path: "/random" },
      { label: "热门", path: "/top" },
      { label: "收藏", path: "/favorites" },
      { label: "浏览", path: "views" },
      { label: "相关", path: "/relevance" },
    ],
  }

  search(keywords) {
    return fetch(`/?q=${keywords}`).then((response) => response.json());
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
    console.log("fetchGallery 请求的path：", path, "page:", page);
    if (!path) {
      path = "date_added";
    }
    return fetch(`${path}?page=${page}`).then((response) => response.json());
  }

  fetchDetails(url) {
    return url;
  }
}

const client = new Client();

export default client;
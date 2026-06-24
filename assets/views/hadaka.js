class Index {
  _info = {
    name: "meizitu",
    title: "妹子图",
    icon: "https://legs.a-hadaka.jp/wp-content/uploads/cropped-nisopink-192x192.jpg",
    website: "https://legs.a-hadaka.jp",
    menus: [
      { label: "最新", path: "/" },
      { label: "绝对领域", value: "/niso" },
      { label: "黑丝", value: "/blacklegs" },
      { label: "狱卒", value: "/namaashi" },
      { label: "美脚", value: "/light" },
    ],
    description: "妹子图是一个专注于分享各种美女图片的网站，提供高清美女图片、性感美女图片、清纯美女图片等内容。",
    keywords: "妹子图, 美女图片, 性感美女, 清纯美女, 高清美女",
  }

  get info() {
    return JSON.stringify(this._info);
  }

  async render(url, page) {
    const html = await fetch(url).then((res) => res.text());
    const dom = await import("dom")
    const container = dom.querySelectorAll(html, "div.foogallery figure")

    const images = JSON.parse(container).map((item) => {
      const img = JSON.parse(dom.querySelector(item.innerHtml, "img"))
      console.log("img", img)
      // data-src-fg
      const src = (img?.attrs?.find((a) => a[0] === "data-src-fg")?.[1] || "");
      const srcFull = src.replace("/cache/", "/");
      // 使用正则将 /91160514.jpg替换为 .jpg
      const srcFinal = srcFull.replace(/\/\d+(\.jpg)/, "$1");
      return `<img alt='${srcFinal}' style="width:100%;object-fit:cover;display:block;" src="${src}" />`;
    });

    const carouselImages = images.slice(0, 5).map((img) =>
      `<div class="image" style="flex:0 0 auto;scroll-snap-align:start;border-radius:12px;overflow:hidden;width:280px;">${img}</div>`
    ).join("\n");

    const gridImages = images.slice(5).join("\n");

    return `
     <div style="padding:12px;">
        <div class="carousel">
          ${carouselImages}
        </div>
        <div style="height:12px;"></div>
        <div class="grid">
         ${gridImages}
        </div>
     </div>
    `

  }
}
const client = new Index()
export default client
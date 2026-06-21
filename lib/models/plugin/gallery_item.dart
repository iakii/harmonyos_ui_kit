/// 图集列表项，对应 getPage() 返回的 list 中的每个元素。
class GalleryItem {
  final String link;
  final String cover;
  final String title;
  // 跳转类型，默认为 "page"，表示打开详情页面；如果是 "gallery"，则打开图集页面。
  final String to;

  const GalleryItem({
    required this.link,
    required this.cover,
    required this.title,
    required this.to,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) => GalleryItem(
    link: json['link'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    title: json['title'] as String? ?? '',
    to: json['to'] as String? ?? 'page',
  );
}

/// 图集分页数据，对应 getPage() 的返回值。
class GalleryPageData {
  final List<GalleryItem> list;
  final int totalPage;
  final int current;

  const GalleryPageData({
    required this.list,
    required this.totalPage,
    required this.current,
  });

  bool get hasMore => current < totalPage;

  factory GalleryPageData.fromJson(Map<String, dynamic> json) =>
      GalleryPageData(
        list:
            (json['list'] as List<dynamic>?)
                ?.map((e) => GalleryItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalPage: (json['totalPage'] as num?)?.toInt() ?? 1,
        current: (json['current'] as num?)?.toInt() ?? 1,
      );
}

/// 详情项，对应 getDetails() 返回的 list 中的每个元素。
class DetailItem {
  final String? cover;
  final String? href;
  final String? title;

  const DetailItem({this.cover, this.href, this.title});

  factory DetailItem.fromJson(Map<String, dynamic> json) => DetailItem(
    cover: json['cover'] as String?,
    href: json['href'] as String?,
    title: json['title'] as String?,
  );
}

/// 详情数据，对应 getDetails() 的返回值。
class GalleryDetail {
  final List<DetailItem> list;
  final int current;

  const GalleryDetail({required this.list, required this.current});

  factory GalleryDetail.fromJson(Map<String, dynamic> json) => GalleryDetail(
    list:
        (json['list'] as List<dynamic>?)
            ?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    current: (json['current'] as num?)?.toInt() ?? 1,
  );
}

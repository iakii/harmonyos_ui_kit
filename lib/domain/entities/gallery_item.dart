import 'detail_item.dart';

/// 图集列表项，对应 getPage() 返回的 list 中的每个元素。
class GalleryItem {
  final String link;
  final String cover;
  final String title;
  // 跳转类型，默认为 "page"，表示打开详情页面；如果是 "gallery"，则打开图集页面。intro 打开简介页面
  final String to;

  final List<DetailItem> tags;

  const GalleryItem({
    required this.link,
    required this.cover,
    required this.title,
    required this.to,
    required this.tags,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) => GalleryItem(
    link: json['link'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    title: json['title'] as String? ?? '',
    to: json['to'] as String? ?? 'page',
    tags:
        (json['tags'] as List<dynamic>?)
            ?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  static String getRoutePath(String to) {
    switch (to) {
      case 'gallery':
        return '/js_gallery_list';
      case 'intro':
        return '/js_intro';
      default:
        return '/js_gallery_detail';
    }
  }
}

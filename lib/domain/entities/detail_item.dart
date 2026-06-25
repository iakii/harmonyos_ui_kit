/// 详情项，对应 getDetails() 返回的 list 中的每个元素。
class DetailItem {
  final String? cover;
  final String? href;
  final String? title;
  final String? to;

  const DetailItem({this.cover, this.href, this.title, this.to});

  factory DetailItem.fromJson(Map<String, dynamic> json) => DetailItem(
    cover: json['cover'] as String?,
    href: json['href'] as String?,
    title: json['title'] as String?,
    to: json['to'] as String?,
  );
}

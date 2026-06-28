import 'detail_item.dart';
import 'gallery_item.dart';

/// 图集分页数据，对应 getPage() 的返回值。
class GalleryPageData {
  final List<GalleryItem> list;
  final int totalPage;
  final int current;
  final bool? needCaptcha;

  const GalleryPageData({
    required this.list,
    required this.totalPage,
    required this.current,
    this.needCaptcha,
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
        needCaptcha: json['needCaptcha'] as bool?,
      );
}

/// 详情数据，对应 getDetails() 的返回值。
class GalleryDetail {
  final List<DetailItem> list;
  final int current;
  final int? totalPage; // 总页数，null=未提供（无分页）
  final String? nextPageUrl; // 下一页 URL，null=未提供（无分页）

  const GalleryDetail({
    required this.list,
    required this.current,
    this.totalPage,
    this.nextPageUrl,
  });

  /// 是否有更多分页数据。
  /// 两者都为 null → 无分页；任意一个非 null 即启用分页。
  bool get hasMore =>
      nextPageUrl != null || (totalPage != null && current < totalPage!);

  factory GalleryDetail.fromJson(Map<String, dynamic> json) => GalleryDetail(
    list:
        (json['list'] as List<dynamic>?)
            ?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    current: (json['current'] as num?)?.toInt() ?? 1,
    totalPage: (json['totalPage'] as num?)?.toInt(), // null 表示未提供
    nextPageUrl: json['nextPageUrl'] as String?, // null 表示未提供
  );
}

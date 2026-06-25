import 'detail_item.dart';
import 'gallery_item.dart';

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

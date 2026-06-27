import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';

/// JS 图集仓库接口。
///
/// 负责通过 JsEngine 获取图集分页列表。
abstract class JsGalleryRepository {
  /// 获取图集分页列表。
  Future<Result<GalleryPageData>> getPage({
    required String url,
    required int page,
  });

  /// 搜索图集（调用 JS [client.search]）。
  ///
  /// 返回格式与 [getPage] 相同，为 [GalleryPageData]。
  /// 如果 JS 客户端未实现 search 方法，将抛出 JS 错误。
  Future<Result<GalleryPageData>> search({
    required String keyword,
    required int page,
  });
}

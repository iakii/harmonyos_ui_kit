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
}

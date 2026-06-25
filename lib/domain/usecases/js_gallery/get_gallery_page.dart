import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/domain/repositories/js_gallery_repository.dart';

/// 获取图集分页列表用例。
class GetGalleryPage {
  final JsGalleryRepository _repository;

  const GetGalleryPage(this._repository);

  Future<Result<GalleryPageData>> call({
    required String url,
    required int page,
  }) {
    return _repository.getPage(url: url, page: page);
  }
}

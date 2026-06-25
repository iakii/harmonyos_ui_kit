import 'dart:async';

import 'package:rohos_app/domain/entities/detail_load_state.dart';
import 'package:rohos_app/domain/repositories/js_gallery_repository.dart';

/// 获取图集详情（渐进式流式加载）用例。
class GetGalleryDetail {
  final JsGalleryRepository _repository;

  const GetGalleryDetail(this._repository);

  Stream<DetailLoadState> call({
    required String url,
    required String jsContent,
    required String name,
  }) {
    return _repository.getDetail(
      url: url,
      jsContent: jsContent,
      name: name,
    );
  }
}

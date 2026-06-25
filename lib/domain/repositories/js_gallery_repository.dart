import 'dart:async';

import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/detail_load_state.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';

/// JS 图集仓库接口。
///
/// 负责通过 JsEngine 获取图集分页列表和详情。
abstract class JsGalleryRepository {
  /// 获取图集分页列表。
  Future<Result<GalleryPageData>> getPage({
    required String url,
    required int page,
  });

  /// 获取图集详情（渐进式流式加载）。
  Stream<DetailLoadState> getDetail({
    required String url,
    required String jsContent,
    required String name,
  });
}

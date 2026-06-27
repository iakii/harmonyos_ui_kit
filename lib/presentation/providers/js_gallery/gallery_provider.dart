import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/repository_providers.dart';

part 'gallery_provider.g.dart';

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。
@riverpod
Future<GalleryPageData> gallery(
  Ref ref, {
  required String url,
  required int page,
}) async {
  final repo = ref.watch(jsGalleryRepositoryProvider);

  final result = await repo.getPage(url: url, page: page);

  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}

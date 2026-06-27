import 'dart:convert';

import 'package:js_runtime/js_runtime.dart';
import 'package:pinyin/pinyin.dart' show PinyinHelper;
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/core/extensions/string.ext.dart';
import 'package:rohos_app/core/utils/logger.dart' show iLogger;
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/domain/repositories/js_gallery_repository.dart';

/// JsGalleryRepository 实现。
///
/// [engineProvider] 是一个异步函数，用于获取共享的 JsEngine 实例。
class JsGalleryRepositoryImpl implements JsGalleryRepository {
  final Future<JsEngine> Function() _engineProvider;

  const JsGalleryRepositoryImpl(this._engineProvider);

  @override
  Future<Result<GalleryPageData>> getPage({
    required String url,
    required int page,
  }) async {
    try {
      final engine = await _engineProvider();

      final result = await engine.eval(
        code:
            '''
      (async () => {
        const { default: client } = await import('client');
        return await client.fetchGallery(${jsonEncode(url)}, $page);
      })()
    ''',
      );

      final jsonStr = result.asStringSync ?? '';

      if (jsonStr.isEmpty || jsonStr == 'undefined') {
        return Failure(NetworkException('获取图集数据失败: $url'));
      }

      final data = GalleryPageData.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      return Success(data);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<GalleryPageData>> search({
    required String keyword,
    required int page,
  }) async {
    try {
      final engine = await _engineProvider();

      // PinyinHelper.getPinyin
      engine.register(
        name: 'toPinYin',
        func: (args) {
          final keyword = jsonDecode(args)[0] as String;
          iLogger.d(
            'toPin called with $args =  args: $keyword  py: ${keyword.pinyin}',
          );
          return Future.value(jsonEncode([keyword.pinyin]));
        },
      );

      final result = await engine.eval(
        code:
            '''
      (async () => {
        const { default: client } = await import('client');
        return await client.search(${jsonEncode(keyword)}, $page);
      })()
    ''',
      );

      final jsonStr = result.asStringSync ?? '';

      if (jsonStr.isEmpty || jsonStr == 'undefined') {
        return Failure(NetworkException('搜索失败: "$keyword"'));
      }

      final data = GalleryPageData.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      return Success(data);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }
}

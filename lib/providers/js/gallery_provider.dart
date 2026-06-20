import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';

import '../../models/app_exception.dart';
import '../../models/plugin/gallery_item.dart';
import 'js_engine_provider.dart';

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 参数 `url` 是完整的请求 URL（如 "https://www.meitula.org/i"），
/// `page` 是页码（从 1 开始）。
final galleryProvider =
    FutureProvider.family<GalleryPageData, ({String url, int page})>((
      ref,
      params,
    ) async {
      final engine = await ref.watch(jsEngineProvider.future);
      final (:url, :page) = params;

      // 用 jsonEncode 安全转义 URL，防止 JS 注入
      final safeUrl = jsonEncode(url);

      final result = engine.eval(
        code:
            '''
      (async () => {
        const { default: client } = await import('client');
        return await client.getPage($safeUrl, $page);
      })()
    ''',
      );

      final jsonStr = result.asStringSync;
      if (jsonStr == null || jsonStr == 'undefined') {
        throw NetworkException('获取图集数据失败: $url');
      }

      return GalleryPageData.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    });

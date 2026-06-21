import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/providers/js/js_engine_provider.dart';

import '../../models/app_exception.dart';
import '../../models/plugin/gallery_item.dart';

part 'gallery_provider.g.dart';

// ─── Providers ──────────────────────────────────────────────────

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 依赖 [jsEngineProvider] 的共享 JsEngine，JS eval 在工作线程执行不阻塞 UI。
@riverpod
Future<GalleryPageData> gallery(
  Ref ref, {
  required String url,
  required int page,
}) async {
  final engine = await ref.watch(jsEngineProvider.future);

  final result = await engine.eval(
    code: '''
    (async () => {
      const { default: client } = await import('client');
      return await client.getPage(${jsonEncode(url)}, $page);
    })()
  ''',
  );

  final jsonStr = result.asStringSync ?? '';

  if (jsonStr.isEmpty || jsonStr == 'undefined') {
    throw NetworkException('获取图集数据失败: $url');
  }

  return GalleryPageData.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}

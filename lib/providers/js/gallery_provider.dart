import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/app_exception.dart';
import '../../models/plugin/gallery_item.dart';

part 'gallery_provider.g.dart';

// ─── Worker 参数 ────────────────────────────────────────────────

typedef _GalleryParams = ({String jsSource, String safeUrl, int page});

// ─── 后台 Worker ─────────────────────────────────────────────────

/// 后台 isolate：复用单个 JsEngine 处理所有 getPage 请求。
///
/// - [onInit] 初始化 flutter_rust_bridge
/// - [onEvent] 首次调用时创建 JsEngine（懒加载），后续复用
/// - [onDispose] 关闭 JsEngine，释放 FFI 资源
@pragma('vm:entry-point')
void _galleryWorker(dynamic params) {
  JsEngine? engine;

  IsolateManagerFunction.customFunction<String, _GalleryParams>(
    params,
    onInit: (controller) async {
      await JsRuntimeLib.init();
    },
    onEvent: (controller, message) async {
      // 懒加载：首次请求时创建 engine 并注册 client 模块
      engine ??= JsEngine.create(
        runtimeOptions: JsRuntimeOptions(
          builtins: JsBuiltinOptions.web(),
          info: 'meitule-gallery',
        ),
        modules: [JsModule(name: 'client', source: message.jsSource)],
      );

      final result = await engine!.eval(
        code: '''
        (async () => {
          const { default: client } = await import('client');
          return await client.getPage(${message.safeUrl}, ${message.page});
        })()
      ''',
      );

      return result.asStringSync ?? '';
    },
    onDispose: (controller) {
      engine?.close();
    },
  );
}

// ─── Providers ──────────────────────────────────────────────────

/// 全局 Gallery isolate 管理器（单例，所有图集请求复用同一 isolate）。
///
/// `keepAlive: true` 确保 isolate 跨请求存活，但 dispose 时会被杀死。
@Riverpod(keepAlive: true)
Future<IsolateManager<String, _GalleryParams>> galleryIsolate(Ref ref) async {
  final isolate = IsolateManager<String, _GalleryParams>.createCustom(
    _galleryWorker,
    workerName: 'gallery',
  );

  ref.onDispose(() => isolate.stop());
  await isolate.start(); // 显式启动，触发 onInit（FRB 初始化）
  return isolate;
}

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
/// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
@riverpod
Future<GalleryPageData> gallery(
  Ref ref, {
  required String url,
  required int page,
}) async {
  final isolate = await ref.watch(galleryIsolateProvider.future);

  final safeUrl = jsonEncode(url);
  final jsSource = await rootBundle.loadString('assets/js/meitule.js');

  final jsonStr = await isolate.compute((
    jsSource: jsSource,
    safeUrl: safeUrl,
    page: page,
  ));

  if (jsonStr.isEmpty || jsonStr == 'undefined') {
    throw NetworkException('获取图集数据失败: $url');
  }

  return GalleryPageData.fromJson(
    jsonDecode(jsonStr) as Map<String, dynamic>,
  );
}

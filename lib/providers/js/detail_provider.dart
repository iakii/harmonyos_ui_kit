import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isolate_manager/isolate_manager.dart';
import 'package:js_runtime/js_runtime.dart';

import '../../models/plugin/gallery_item.dart';

// ─── Worker 参数 ────────────────────────────────────────────────

typedef _DetailParams = ({String jsSource, String safeUrl});

// ─── 后台 Worker ─────────────────────────────────────────────────

/// 后台 isolate：独立创建 JsEngine → eval(getDetails) → 回传进度和结果。
///
/// 使用 [IsolateManagerFunction.customFunction]：
/// - [onInit] 初始化 flutter_rust_bridge
/// - [onEvent] 每次 compute() 调用时执行 JS eval，进度通过 sendResult() 实时回传
@pragma('vm:entry-point')
void _detailWorker(dynamic params) {
  IsolateManagerFunction.customFunction<Map<String, dynamic>, _DetailParams>(
    params,
    onInit: (controller) async {
      await JsRuntimeLib.init();
    },
    onEvent: (controller, message) async {
      final engine = JsEngine.create(
        runtimeOptions: JsRuntimeOptions(
          builtins: await JsBuiltinOptions.web(),
          info: 'meitule-detail',
        ),
        modules: [JsModule(name: 'client', source: message.jsSource)],
      );

      try {
        final handler = JsCallbackHandler(engine);

        handler.register('postMessage', (args) {
          final type = args[0].asStringSync ?? '';
          final data = args[1].asStringSync ?? '';
          if (type == 'sendChannelDetails') {
            controller.sendResult({'type': 'progress', 'data': data});
          }
          return JsValue.none();
        });

        final result = handler.eval('''
          (async () => {
            const { default: client } = await import('client');
            return await client.getDetails(${message.safeUrl}, true);
          })()
        ''');

        final finalJson = result.asStringSync ?? '';
        controller.sendResult({'type': 'final', 'data': finalJson});
      } catch (e) {
        controller.sendResult({'type': 'error', 'data': e.toString()});
      } finally {
        engine.close();
      }

      return <String, dynamic>{}; // autoHandleResult=false 时不使用
    },
    autoHandleException: false,
    autoHandleResult: false,
  );
}

// ─── 加载状态 ───────────────────────────────────────────────────

/// 详情加载状态（渐进式）。
class DetailLoadState {
  final List<DetailItem> items;
  final bool isLoading;
  final bool isComplete;
  final String? error;
  final int batchCount;

  const DetailLoadState({
    required this.items,
    required this.isLoading,
    required this.isComplete,
    this.error,
    this.batchCount = 0,
  });

  static const initial = DetailLoadState(
    items: [],
    isLoading: true,
    isComplete: false,
  );
}

// ─── StreamProvider ─────────────────────────────────────────────

/// 详情加载 Provider（按链接 URL）。
///
/// 使用 [IsolateManager.createCustom] 管理后台 isolate：
/// - 进度数据通过 callback 实时推送到 Stream
/// - 最终结果通过 compute() 返回
/// - dispose 时 isolate.stop() 安全终止（不损坏 FFI 资源）
final detailLoadProvider = StreamProvider.autoDispose
    .family<DetailLoadState, String>((ref, url) {
  final controller = StreamController<DetailLoadState>();
  IsolateManager<Map<String, dynamic>, _DetailParams>? isolate;
  var disposed = false;

  Future<void> startLoading() async {
    controller.add(DetailLoadState.initial);

    try {
      // 1. 主 isolate 加载 JS 源码
      final jsSource = await rootBundle.loadString('assets/js/meitule.js');
      final safeUrl = jsonEncode(url);

      // 2. 创建 isolate manager
      isolate = IsolateManager<Map<String, dynamic>, _DetailParams>.createCustom(
        _detailWorker,
        workerName: 'detail',
      );

      if (disposed) return;

      // 3. 执行 JS eval（后台 isolate）
      final progressJsons = <String>[];

      final result = await isolate!.compute(
        (jsSource: jsSource, safeUrl: safeUrl),
        callback: (event) {
          if (disposed || controller.isClosed) return true;

          final type = event['type'] as String;

          if (type == 'progress') {
            progressJsons.add(event['data'] as String);

            // 逐批展示进度
            for (var i = 0; i < progressJsons.length; i++) {
              if (disposed || controller.isClosed) break;

              try {
                final json = jsonDecode(progressJsons[i])
                    as Map<String, dynamic>;
                final listJson = json['list'] as List<dynamic>?;
                if (listJson != null) {
                  final items = listJson
                      .map((e) =>
                          DetailItem.fromJson(e as Map<String, dynamic>))
                      .toList();

                  controller.add(
                    DetailLoadState(
                      items: items,
                      isLoading: true,
                      isComplete: false,
                      batchCount: i + 1,
                    ),
                  );
                }
              } catch (_) {}
            }
          }

          return type == 'final' || type == 'error';
        },
      );

      if (disposed || controller.isClosed) return;

      // 4. 处理最终结果
      final type = result['type'] as String;
      final data = result['data'] as String?;

      if (type == 'error') {
        controller.add(
          DetailLoadState(
            items: [],
            isLoading: false,
            isComplete: true,
            error: data,
          ),
        );
      } else if (data == null || data.isEmpty || data == 'undefined') {
        controller.add(
          DetailLoadState(
            items: [],
            isLoading: false,
            isComplete: true,
            error: '获取详情失败: 返回数据为空',
          ),
        );
      } else {
        final parsed = jsonDecode(data) as Map<String, dynamic>;
        final detail = GalleryDetail.fromJson(parsed);

        controller.add(
          DetailLoadState(
            items: detail.list,
            isLoading: false,
            isComplete: true,
            batchCount: progressJsons.length,
          ),
        );
      }
    } catch (e) {
      if (!disposed && !controller.isClosed) {
        controller.add(
          DetailLoadState(
            items: [],
            isLoading: false,
            isComplete: true,
            error: e.toString(),
          ),
        );
      }
    }

    if (!disposed && !controller.isClosed) {
      controller.close();
    }
  }

  // 启动加载
  startLoading();

  ref.onDispose(() {
    disposed = true;
    isolate?.stop(); // 安全：自动触发 onDispose → engine.close()
    controller.close();
  });

  return controller.stream;
});

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:harmonyos_ui/harmonyos_ui.dart' show debugPrint;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';

import '../../models/plugin/gallery_item.dart';

// ─── Isolate 通信 ──────────────────────────────────────────────

typedef _IsolateParams = ({SendPort sendPort, String jsSource, String safeUrl});

/// 后台 isolate：独立创建 JsEngine → eval(getDetails) → pollMessages → 回传。
///
/// 整个流程在后台线程完成，不阻塞主 UI。
/// 收集到的所有 __postMessage('sendChannelDetails', ...) 进度
/// 和最终的 getDetails 返回值通过 [SendPort] 逐批发回主 isolate。
void _runInIsolate(_IsolateParams params) async {
  final sendPort = params.sendPort;

  try {
    // 1. 在后台 isolate 初始化 FRB
    await JsRuntimeLib.init();

    // 2. 创建独立的 JsEngine（加载 meitule.js）
    final engine = JsEngine.create(
      runtimeOptions: JsRuntimeOptions(
        builtins: await JsBuiltinOptions.web(),
        info: 'meitule-detail',
      ),
      modules: [JsModule(name: 'client', source: params.jsSource)],
    );

    final handler = JsCallbackHandler(engine);
    debugPrint('注册 postMessage 回调');
    // 直接传入 Dart 函数 —— 看起来就像直接注入
    handler.register('postMessage', (args) {
      debugPrint('Received from JS:  data=$args');
      final type = args[0].asStringSync ?? '';
      final data = args[1].asStringSync ?? '';
      debugPrint('Received from JS: type=$type, data=$data');
      if (type == 'sendChannelDetails') {
        sendPort.send({'type': 'progress', 'data': data});
      }
      if (type == 'stopLoading') {
        debugPrint('Received stopLoading signal from JS');
      }
      return JsValue.none();
    });

    final result = handler.eval('''
     (async () => {
        const { default: client } = await import('client');
        return await client.getDetails(${params.safeUrl}, true);
      })()
  ''');

    // 6. 发送最终结果
    final finalJson = result.asStringSync ?? '';
    sendPort.send({'type': 'final', 'data': finalJson});

    engine.close();
  } catch (e) {
    sendPort.send({'type': 'error', 'data': e.toString()});
  }
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
/// 在后台 isolate 中执行完整的 getDetails 流程：
/// - eval 阻塞后台线程，不影响主 UI
/// - pollMessages 收集所有 sendChannelDetails 进度
/// - 通过 SendPort 将进度 + 最终结果发回主 isolate
/// - 主 isolate 以 300ms 间隔逐步推送到 Stream，UI 渐进展示
final detailLoadProvider = StreamProvider.family<DetailLoadState, String>((
  ref,
  url,
) {
  final controller = StreamController<DetailLoadState>();

  _startLoading(controller, url);

  ref.onDispose(() => controller.close());

  return controller.stream;
});

Future<void> _startLoading(
  StreamController<DetailLoadState> controller,
  String url,
) async {
  // 1. 初始状态
  controller.add(DetailLoadState.initial);

  try {
    // 2. 主 isolate 加载 JS 源码
    final jsSource = await rootBundle.loadString('assets/js/meitule.js');
    final safeUrl = jsonEncode(url);

    // 3. 启动后台 isolate
    final receivePort = ReceivePort();
    final completer = Completer<void>();

    final progressJsons = <String>[];
    String? finalJson;
    String? errorMsg;

    receivePort.listen((message) {
      if (message is Map<String, dynamic>) {
        switch (message['type'] as String?) {
          case 'progress':
            progressJsons.add(message['data'] as String);

            // 6. 逐批延时展示进度（模拟渐进加载效果）
            for (var i = 0; i < progressJsons.length; i++) {
              if (controller.isClosed) return;

              final jsonStr = progressJsons[i];
              try {
                final json = jsonDecode(jsonStr) as Map<String, dynamic>;
                final listJson = json['list'] as List<dynamic>?;
                if (listJson != null) {
                  final items = listJson
                      .map(
                        (e) => DetailItem.fromJson(e as Map<String, dynamic>),
                      )
                      .toList();

                  controller.add(
                    DetailLoadState(
                      items: items,
                      isLoading: true,
                      isComplete: false,
                      batchCount: i + 1,
                    ),
                  );

                  // 每批之间间隔 300ms，给 UI 时间渲染
                  // await Future.delayed(const Duration(milliseconds: 300));
                }
              } catch (_) {}
            }

          case 'final':
            finalJson = message['data'] as String;
            if (!completer.isCompleted) completer.complete();
          case 'error':
            errorMsg = message['data'] as String;
            if (!completer.isCompleted) completer.complete();
        }
      }
    });

    await Isolate.spawn(_runInIsolate, (
      sendPort: receivePort.sendPort,
      jsSource: jsSource,
      safeUrl: safeUrl,
    ));

    // 4. 等待后台 isolate 完成（期间无法实时获取进度，
    //    因为 eval 阻塞了后台 isolate，所有消息在 eval 后才发出）
    await completer.future;
    receivePort.close();

    // 5. 错误处理
    if (errorMsg != null) {
      if (!controller.isClosed) {
        controller.add(
          DetailLoadState(
            items: [],
            isLoading: false,
            isComplete: true,
            error: errorMsg,
          ),
        );
        controller.close();
      }
      return;
    }

    if (controller.isClosed) return;

    // 7. 最终结果
    if (finalJson == null || finalJson!.isEmpty || finalJson == 'undefined') {
      controller.add(
        DetailLoadState(
          items: [],
          isLoading: false,
          isComplete: true,
          error: '获取详情失败: 返回数据为空',
        ),
      );
    } else {
      try {
        final parsed = jsonDecode(finalJson!) as Map<String, dynamic>;
        final detail = GalleryDetail.fromJson(parsed);

        controller.add(
          DetailLoadState(
            items: detail.list,
            isLoading: false,
            isComplete: true,
            batchCount: progressJsons.length,
          ),
        );
      } catch (e) {
        controller.add(
          DetailLoadState(
            items: [],
            isLoading: false,
            isComplete: true,
            error: '解析结果失败: $e',
          ),
        );
      }
    }
  } catch (e) {
    if (!controller.isClosed) {
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

  if (!controller.isClosed) {
    controller.close();
  }
}

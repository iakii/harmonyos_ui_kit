import 'dart:convert';
import 'dart:isolate';

import 'package:js_runtime/js_runtime.dart';

/// Worker 初始化参数 — 用于启动 Isolate 加载图集详情。
///
/// [current] 为 null → 渐进式加载（逐批推送 progress 消息），
/// [current] 非 null → 单页加载（仅推送 final 消息，JS 传页码）。
class DetailWorkerInit {
  final String jsSource;
  final String url;
  final SendPort sendPort;
  final String name;

  /// 可选页码，null 表示全量渐进式加载，非 null 表示单页分页加载。
  final int? current;

  const DetailWorkerInit({
    required this.jsSource,
    required this.url,
    required this.sendPort,
    required this.name,
    this.current,
  });
}

/// Isolate 通信消息类型常量。
abstract class DetailWorkerMsg {
  static const progress = 'progress';
  static const final_ = 'final';
  static const error = 'error';
}

/// 在后台 Isolate 中执行详情加载（合并渐进式 + 单页两种模式）。
///
/// 行为由 [DetailWorkerInit.current] 决定：
/// - null → 渐进式：注册详细 postMessage 回调，逐批推送 progress
/// - 非 null → 单页：postMessage 静默处理，JS 额外传入 page 参数
@pragma('vm:entry-point')
Future<void> runDetailWorker(DetailWorkerInit init) async {
  await JsRuntimeLib.init();

  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: JsBuiltinOptions.all(),
      info: init.name,
    ),
    modules: [JsModule(name: 'client', source: init.jsSource)],
  );

  try {
    final isProgressive = init.current == null;
    final progressJsons = <String>[];
    var batch = 0;

    if (isProgressive) {
      // 渐进式：捕获 sendChannelDetails 逐批推送
      await engine.register(
        name: 'postMessage',
        func: (String argsJson) async {
          final args = jsonDecode(argsJson) as List;
          final type = args[0] as String? ?? '';
          final data = args[1] as String? ?? '';
          if (type != 'sendChannelDetails') return jsonEncode(null);

          progressJsons.add(data);
          batch++;
          init.sendPort.send({
            'type': DetailWorkerMsg.progress,
            'data': List<String>.from(progressJsons),
            'batch': batch,
          });
          return jsonEncode(null);
        },
      );
    } else {
      // 单页：静默处理 postMessage
      await engine.register(
        name: 'postMessage',
        func: (String argsJson) async => jsonEncode(null),
      );
    }

    // 构造 JS 调用
    final jsCode = isProgressive
        ? '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)});
      })()
    '''
        : '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)}, ${init.current});
      })()
    ''';

    final result = await engine.eval(code: jsCode);

    if (isProgressive) {
      init.sendPort.send({
        'type': DetailWorkerMsg.final_,
        'data': result.asStringSync ?? '',
        'batch': batch,
      });
    } else {
      init.sendPort.send({
        'type': DetailWorkerMsg.final_,
        'data': result.asStringSync ?? '',
      });
    }
  } catch (e) {
    init.sendPort.send({'type': DetailWorkerMsg.error, 'error': e.toString()});
  } finally {
    engine.close();
  }
}

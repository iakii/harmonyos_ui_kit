import 'dart:convert';
import 'dart:isolate';

import 'package:js_runtime/js_runtime.dart';

/// Worker 初始化参数 — 用于启动 Isolate 加载图集详情。
class DetailWorkerInit {
  final String jsSource;
  final String url;
  final SendPort sendPort;
  final String name;

  /// 可选页码（单页加载模式使用），null 表示全量渐进式加载。
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

/// 在后台 Isolate 中执行渐进式详情加载。
///
/// 注册 `postMessage` Dart 回调，将 JS 端 `sendChannelDetails` 消息
/// 逐批推送到主 Isolate。
@pragma('vm:entry-point')
Future<void> runProgressiveDetailWorker(DetailWorkerInit init) async {
  await JsRuntimeLib.init();

  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: JsBuiltinOptions.all(),
      info: init.name,
    ),
    modules: [JsModule(name: 'client', source: init.jsSource)],
  );

  try {
    final progressJsons = <String>[];
    var batch = 0;

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

    final result = await engine.eval(
      code: '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)});
      })()
    ''',
    );

    init.sendPort.send({
      'type': DetailWorkerMsg.final_,
      'data': result.asStringSync ?? '',
      'batch': batch,
    });
  } catch (e) {
    init.sendPort.send({'type': DetailWorkerMsg.error, 'error': e.toString()});
  } finally {
    engine.close();
  }
}

/// 在后台 Isolate 中执行单页详情加载。
///
/// 不推送进度，仅返回最终结果。可传入 [current] 页码。
@pragma('vm:entry-point')
Future<void> runSinglePageDetailWorker(DetailWorkerInit init) async {
  await JsRuntimeLib.init();

  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: JsBuiltinOptions.all(),
      info: init.name,
    ),
    modules: [JsModule(name: 'client', source: init.jsSource)],
  );

  try {
    // 注册 postMessage 回调，JS 端调用时不报错即可（忽略进度）
    await engine.register(
      name: 'postMessage',
      func: (String argsJson) async => jsonEncode(null),
    );

    // 构造 JS 调用：有 current 时传 page，否则不带
    final jsCode = init.current != null
        ? '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)}, ${init.current});
      })()
    '''
        : '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)});
      })()
    ''';

    final result = await engine.eval(code: jsCode);

    init.sendPort.send({
      'type': DetailWorkerMsg.final_,
      'data': result.asStringSync ?? '',
    });
  } catch (e) {
    init.sendPort.send({'type': DetailWorkerMsg.error, 'error': e.toString()});
  } finally {
    engine.close();
  }
}

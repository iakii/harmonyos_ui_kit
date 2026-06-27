import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:js_runtime/js_runtime.dart';

import 'package:rohos_app/domain/entities/gallery_detail.dart';

/// 详情页 Worker 池 — 复用常驻 Isolate，避免反复 spawn/kill。
///
/// 池中维护一个常驻 Isolate，内部已初始化 [JsRuntimeLib]。
/// 每个任务：创建 JsEngine → eval → 返回结果 → 关闭 JsEngine。
/// 通过 [Completer] 实现异步返回，支持并发任务排队。
class DetailWorkerPool {
  static const _initTimeout = Duration(seconds: 10);
  static const _taskTimeout = Duration(seconds: 30);

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _nextTaskId = 0;
  final Map<int, Completer<GalleryDetail>> _pending = {};
  bool _disposed = false;

  /// 启动常驻 Isolate 并等待就绪。
  Future<void> init() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _poolEntryPoint,
      _receivePort!.sendPort,
      debugName: 'DetailWorkerPool',
    );

    // 等待 worker 发回它的 SendPort（表示 JsRuntimeLib 初始化完成）
    _sendPort = await _receivePort!.first.timeout(_initTimeout) as SendPort;

    // 持续监听 worker 返回结果
    _receivePort!.listen(_onMessage, onError: _onError);
  }

  void _onMessage(dynamic message) {
    final msg = message as Map<String, dynamic>;
    final taskId = msg['taskId'] as int;
    if (_disposed) return;

    final completer = _pending.remove(taskId);
    if (completer == null) return; // 超时已处理

    switch (msg['type'] as String) {
      case 'data':
        final jsonStr = msg['data'] as String;
        try {
          final detail = GalleryDetail.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
          completer.complete(detail);
        } catch (e) {
          completer.completeError(
            Exception('解析详情数据失败: $e'),
          );
        }
      case 'error':
        completer.completeError(Exception(msg['error'] as String));
    }
  }

  void _onError(Object error) {
    // Worker Isolate 崩溃 — 通知所有等待的任务
    if (_disposed) return;
    for (final entry in _pending.entries) {
      entry.value.completeError(
        Exception('Worker 异常: $error'),
      );
    }
    _pending.clear();
    _disposed = true;
  }

  /// 提交一个详情加载任务，返回结果 Future。
  Future<GalleryDetail> execute({
    required String url,
    required String jsSource,
    required String name,
    required int current,
  }) async {
    if (_disposed || _sendPort == null) {
      throw Exception('WorkerPool 不可用，请重新初始化');
    }

    final taskId = _nextTaskId++;
    final completer = Completer<GalleryDetail>();

    _pending[taskId] = completer;

    _sendPort!.send({
      'taskId': taskId,
      'url': url,
      'jsSource': jsSource,
      'name': name,
      'current': current,
    });

    // 超时保护
    final result = await completer.future.timeout(
      _taskTimeout,
      onTimeout: () {
        _pending.remove(taskId);
        throw TimeoutException('详情加载超时');
      },
    );

    return result;
  }

  /// 释放 Worker 池。
  Future<void> dispose() async {
    _disposed = true;
    _sendPort = null;
    _receivePort?.close();
    _receivePort = null;
    try {
      _isolate?.kill(priority: Isolate.immediate);
    } catch (_) {}
    _isolate = null;
    _pending.clear();
  }
}

/// Worker 池的 Isolate 入口点。
///
/// 初始化 [JsRuntimeLib]，然后循环处理任务。
@pragma('vm:entry-point')
Future<void> _poolEntryPoint(SendPort mainSendPort) async {
  await JsRuntimeLib.init();

  final receivePort = ReceivePort();
  // 通知主 Isolate：我已就绪
  mainSendPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    final task = message as Map<String, dynamic>;
    final taskId = task['taskId'] as int;
    final url = task['url'] as String;
    final jsSource = task['jsSource'] as String;
    final name = task['name'] as String;
    final current = task['current'] as int;

    JsEngine? engine;
    try {
      engine = JsEngine.create(
        runtimeOptions: JsRuntimeOptions(
          builtins: JsBuiltinOptions.all(),
          info: name,
        ),
        modules: [JsModule(name: 'client', source: jsSource)],
      );

      // 注册 postMessage 回调（静默处理）
      await engine.register(
        name: 'postMessage',
        func: (String argsJson) async => jsonEncode(null),
      );

      final result = await engine.eval(
        code: '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(url)}, $current);
      })()
    ''',
      );

      mainSendPort.send({
        'taskId': taskId,
        'type': 'data',
        'data': result.asStringSync ?? '',
      });
    } catch (e) {
      mainSendPort.send({
        'taskId': taskId,
        'type': 'error',
        'error': e.toString(),
      });
    } finally {
      engine?.close();
    }
  }
}

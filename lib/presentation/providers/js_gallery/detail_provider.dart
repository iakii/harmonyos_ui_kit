import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:js_runtime/js_runtime.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/domain/entities/detail_item.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart';

part 'detail_provider.g.dart';

// ─── 加载状态 ───────────────────────────────────────────────────

/// 详情加载状态（渐进式）。
class DetailLoadState {
  final List<DetailItem> items;
  final bool isLoading;
  final bool isComplete;
  final String? error;
  final int batchCount;
  final int? totalPage; // 总页数，null=未提供
  final String? nextPageUrl; // 下一页 URL，null=未提供
  final int current; // 当前页号

  const DetailLoadState({
    required this.items,
    required this.isLoading,
    required this.isComplete,
    this.error,
    this.batchCount = 0,
    this.totalPage,
    this.nextPageUrl,
    this.current = 1,
  });

  /// 是否有更多分页数据。
  bool get hasMore =>
      nextPageUrl != null || (totalPage != null && current < totalPage!);

  static const initial = DetailLoadState(
    items: [],
    isLoading: true,
    isComplete: false,
  );

  factory DetailLoadState.error(String message) => DetailLoadState(
    items: [],
    isLoading: false,
    isComplete: true,
    error: message,
  );

  factory DetailLoadState.done({
    required List<DetailItem> items,
    int batchCount = 0,
    int? totalPage,
    String? nextPageUrl,
    int current = 1,
  }) =>
      DetailLoadState(
        items: items,
        isLoading: false,
        isComplete: true,
        batchCount: batchCount,
        totalPage: totalPage,
        nextPageUrl: nextPageUrl,
        current: current,
      );
}

// ─── Worker 通信 ────────────────────────────────────────────────

/// 主 isolate → Worker。
class _WorkerInit {
  final String jsSource;
  final String url;
  final SendPort sendPort;
  final String name;
  const _WorkerInit({
    required this.jsSource,
    required this.url,
    required this.sendPort,
    required this.name,
  });
}

abstract class _Msg {
  static const progress = 'progress';
  static const final_ = 'final';
  static const error = 'error';
}

// ─── Provider ───────────────────────────────────────────────────

/// 详情加载 Provider（按链接 URL）。
///
/// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
/// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
/// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
@riverpod
class DetailLoad extends _$DetailLoad {
  final _controller = StreamController<DetailLoadState>();
  Isolate? _isolate;
  ReceivePort? _receivePort;

  @override
  Stream<DetailLoadState> build(String url) {
    ref.onDispose(() {
      Logger().d('DetailLoadProvider: dispose, kill isolate');

      // 先关 ReceivePort，强制 await for 退出（避免等消息卡住）
      _receivePort?.close();
      _receivePort = null;

      try {
        _isolate?.kill(priority: Isolate.immediate);
      } catch (_) {}
      _isolate = null;

      if (!_controller.isClosed) _controller.close();
    });

    _startLoad(url);
    return _controller.stream;
  }

  Future<void> _startLoad(String url) async {
    _controller.add(DetailLoadState.initial);
    Isolate? isolate; // 局部引用，finally 中兜底 kill

    final config = await ref.watch(jsConfigProvider.future);

    try {
      if (_controller.isClosed) return;

      _receivePort = ReceivePort();
      isolate = await Isolate.spawn(
        _detailWorker,
        _WorkerInit(
          jsSource: config.jsContent,
          url: url,
          name: config.name,
          sendPort: _receivePort!.sendPort,
        ),
        debugName: 'DetailWorker',
      );
      _isolate = isolate;
      if (_controller.isClosed) return; // dispose 可能在 spawn await 期间触发

      await for (final message in _receivePort!) {
        if (_controller.isClosed) break;
        _handleMessage(message as Map<String, Object?>);
      }
    } catch (e) {
      if (!_controller.isClosed) {
        _controller.add(DetailLoadState.error(e.toString()));
      }
    } finally {
      try {
        isolate?.kill(priority: Isolate.immediate);
      } catch (_) {}
      _isolate = null;
      _receivePort?.close();
      _receivePort = null;
    }
  }

  void _handleMessage(Map<String, Object?> msg) {
    switch (msg['type'] as String) {
      case _Msg.progress:
        final jsons = (msg['data'] as List).cast<String>();
        _emitProgress(jsons, msg['batch'] as int);
      case _Msg.final_:
        _emitFinal(msg['data'] as String, msg['batch'] as int);
      case _Msg.error:
        _controller.add(DetailLoadState.error(msg['error'] as String));
    }
  }

  // ─── 状态推送 ─────────────────────────────────────────────────

  void _emitProgress(List<String> jsons, int batch) {
    for (var i = 0; i < jsons.length; i++) {
      if (_controller.isClosed) return;
      try {
        final json = jsonDecode(jsons[i]) as Map<String, dynamic>;
        final list = json['list'] as List<dynamic>?;
        if (list != null) {
          _controller.add(
            DetailLoadState(
              items: list
                  .map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
                  .toList(),
              isLoading: true,
              isComplete: false,
              batchCount: i + 1,
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _emitFinal(String jsonStr, int batch) {
    if (jsonStr.isEmpty || jsonStr == 'undefined') {
      _controller.add(DetailLoadState.error('获取详情失败: 返回数据为空'));
      return;
    }
    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
    final detail = GalleryDetail.fromJson(parsed);
    _controller.add(
      DetailLoadState.done(
        items: detail.list,
        batchCount: batch,
        totalPage: detail.totalPage,
        nextPageUrl: detail.nextPageUrl,
        current: detail.current,
      ),
    );
  }
}

// ─── 后台 Worker ─────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _detailWorker(_WorkerInit init) async {
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
          'type': _Msg.progress,
          'data': List<String>.from(progressJsons),
          'batch': batch,
        });
        return jsonEncode(null);
      },
    );

    final result = await engine.eval(
      code:
          '''
      (async () => {
        const dom = await import('dom');
        const { default: client } = await import('client');
        return await client.fetchDetails(${jsonEncode(init.url)});
      })()
    ''',
    );

    init.sendPort.send({
      'type': _Msg.final_,
      'data': result.asStringSync ?? '',
      'batch': batch,
    });
  } catch (e) {
    init.sendPort.send({'type': _Msg.error, 'error': e.toString()});
  } finally {
    engine.close();
  }
}

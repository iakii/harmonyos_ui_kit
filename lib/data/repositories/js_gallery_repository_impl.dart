import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/data/datasources/remote/detail_worker.dart';
import 'package:rohos_app/domain/entities/detail_item.dart';
import 'package:rohos_app/domain/entities/detail_load_state.dart';
import 'package:rohos_app/domain/entities/gallery_detail.dart';
import 'package:rohos_app/domain/repositories/js_gallery_repository.dart';

// ─── Repository 实现 ───────────────────────────────────────────────

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
        code: '''
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
  Stream<DetailLoadState> getDetail({
    required String url,
    required String jsContent,
    required String name,
  }) {
    final controller = StreamController<DetailLoadState>();
    _startDetailLoad(url, jsContent, name, controller);
    return controller.stream;
  }

  Future<void> _startDetailLoad(
    String url,
    String jsContent,
    String name,
    StreamController<DetailLoadState> controller,
  ) async {
    controller.add(DetailLoadState.initial);
    Isolate? isolate;
    ReceivePort? receivePort;

    try {
      receivePort = ReceivePort();
      isolate = await Isolate.spawn(
        runProgressiveDetailWorker,
        DetailWorkerInit(
          jsSource: jsContent,
          url: url,
          name: name,
          sendPort: receivePort.sendPort,
        ),
        debugName: 'DetailWorker',
      );

      await for (final message in receivePort) {
        if (controller.isClosed) break;
        _handleMessage(message as Map<String, Object?>, controller);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.add(DetailLoadState.error(e.toString()));
      }
    } finally {
      try {
        isolate?.kill(priority: Isolate.immediate);
      } catch (_) {}
      receivePort?.close();
      receivePort = null;
    }
  }

  void _handleMessage(
    Map<String, Object?> msg,
    StreamController<DetailLoadState> controller,
  ) {
    switch (msg['type'] as String) {
      case DetailWorkerMsg.progress:
        final jsons = (msg['data'] as List).cast<String>();
        _emitProgress(jsons, controller);
      case DetailWorkerMsg.final_:
        _emitFinal(msg['data'] as String, msg['batch'] as int, controller);
      case DetailWorkerMsg.error:
        controller.add(DetailLoadState.error(msg['error'] as String));
    }
  }

  void _emitProgress(
    List<String> jsons,
    StreamController<DetailLoadState> controller,
  ) {
    for (var i = 0; i < jsons.length; i++) {
      if (controller.isClosed) return;
      try {
        final json = jsonDecode(jsons[i]) as Map<String, dynamic>;
        final list = json['list'] as List<dynamic>?;
        if (list != null) {
          controller.add(DetailLoadState(
            items: list
                .map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
                .toList(),
            isLoading: true,
            isComplete: false,
            batchCount: i + 1,
          ));
        }
      } catch (_) {}
    }
  }

  void _emitFinal(
    String jsonStr,
    int batch,
    StreamController<DetailLoadState> controller,
  ) {
    if (jsonStr.isEmpty || jsonStr == 'undefined') {
      controller.add(DetailLoadState.error('获取详情失败: 返回数据为空'));
      return;
    }
    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
    final detail = GalleryDetail.fromJson(parsed);
    controller.add(
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

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:js_runtime/js_runtime.dart' show JsValueExt;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/utils/logger.dart' show iLogger;
import 'package:rohos_app/domain/entities/detail_item.dart' show DetailItem;
import 'package:rohos_app/presentation/providers/js_engine/js_engine_provider.dart'
    show jsEngineProvider;

part 'intro_provider.g.dart';

/// 漫画简介页面数据，对应 fetchIntro 的 JSON 返回结构。
class IntroData {
  final String title;
  final String cover;
  final String author;
  final String category;
  final String status;
  final String description;
  final List<DetailItem> tags;
  final List<DetailItem> list; // 章节列表

  const IntroData({
    this.title = '',
    this.cover = '',
    this.author = '',
    this.category = '',
    this.status = '',
    this.description = '',
    this.tags = const [],
    this.list = const [],
  });

  factory IntroData.fromJson(Map<String, dynamic> json) {
    return IntroData(
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      author: json['author'] as String? ?? '',
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => DetailItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory IntroData.empty() => const IntroData();
}

@riverpod
class JsIntro extends _$JsIntro {
  late String _url;

  @override
  IntroData build(String url) {
    _url = url;
    return IntroData.empty();
  }

  /// 执行 JS fetchIntro() 并解析返回数据更新状态。
  Future<void> refresh() async {
    final engine = await ref.watch(jsEngineProvider.future);

    final result = await engine.eval(
      code:
          '''
    (async () => {
      const { default: client } = await import('client');
      return client.fetchIntro(${jsonEncode(_url)});
    })()
  ''',
    );

    final jsonStr = result.asStringSync ?? '';

    if (jsonStr.isEmpty || jsonStr == 'undefined') {
      throw NetworkException('获取简介数据失败: $_url');
    }

    iLogger.d('JsIntro.refresh: $_url → $jsonStr');

    final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
    state = IntroData.fromJson(parsed);
  }
}

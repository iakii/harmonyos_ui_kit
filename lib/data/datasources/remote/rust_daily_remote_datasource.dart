import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/utils/logger.dart';

/// Rust Daily 远程数据源。
///
/// 负责通过 HTTP 获取 Rust Daily 的 HTML 并解析为结构化数据。
class RustDailyRemoteDataSource {
  final Dio _dio;

  const RustDailyRemoteDataSource(this._dio);

  /// 获取 Rust Daily 分页列表。
  Future<RustDailyListResult> getList({
    required String url,
    required int page,
  }) async {
    final baseUrl = url.startsWith("http") ? url : "https://rustcc.cn$url";

    final fetchUrl =
        "$baseUrl${baseUrl.contains('?') ? '&' : '?'}current_page=$page";

    final response = await _dio.get(fetchUrl);

    if (response.statusCode != 200) {
      throw NetworkException(
        '请求失败: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final dom = parse(response.data).documentElement;
    if (dom == null) {
      throw ParseException('HTML 解析失败：documentElement 为空');
    }

    final pagination = dom.querySelectorAll('div.paginator a');
    final totalPage = pagination.isNotEmpty
        ? (int.tryParse(pagination.last.text) ?? 1)
        : 1;

    final liItems = dom.querySelectorAll('li').map((li) {
      li.attributes['class'] = 'shared-li';
      return li.outerHtml;
    }).toList();

    iLogger.i('Rust Daily 列表模式：共 ${liItems.length} 条 <li>，总页数 $totalPage');

    final html =
        '''
<div style="padding:16px">
${liItems.join('\n')}
</div>''';

    return RustDailyListResult(
      html: html,
      liItems: liItems,
      totalPage: totalPage,
    );
  }

  /// 获取 Rust Daily 文章详情。
  Future<String> getDetail({required String url}) async {
    final baseUrl = url.startsWith("http") ? url : "https://rustcc.cn$url";

    final response = await _dio.get(baseUrl);

    if (response.statusCode != 200) {
      throw NetworkException(
        '请求失败: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final dom = parse(response.data).documentElement;
    if (dom == null) {
      throw ParseException('HTML 解析失败：documentElement 为空');
    }

    final element = dom.querySelector('div.detail-body');
    return '''
<div style="padding:16px">
${element?.outerHtml ?? '暂无内容'}
</div>''';
  }
}

/// Rust Daily 列表解析结果。
class RustDailyListResult {
  final String html;
  final List<String> liItems;
  final int totalPage;

  const RustDailyListResult({
    required this.html,
    required this.liItems,
    required this.totalPage,
  });
}

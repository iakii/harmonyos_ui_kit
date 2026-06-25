import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:html/parser.dart' show parse;
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/presentation/providers/init/dio_provider.dart';
import 'package:rohos_app/core/utils/logger.dart';

part 'rust_daily_provider.g.dart';

/// Rust Daily 数据 Provider。
///
/// 根据 [url]、[type]、[page] 获取并解析 HTML。
/// - type == "list" 时追加 `&current_page=$page`，解析 `<li>` 列表和 paginator
/// - type == "detail" 时直接获取 `div.detail-body` 内容
@riverpod
class RustDaily extends _$RustDaily {
  @override
  FutureOr<RustDailyPageData> build(RustDailyParams params) async {
    final dio = ref.read(dioClientProvider).dio;

    final baseUrl = params.url.startsWith("http")
        ? params.url
        : "https://rustcc.cn${params.url}";

    // list 类型时追加分页参数（根据 URL 是否已有 query string 决定 ? 或 &）
    final fetchUrl = params.type == "list"
        ? "$baseUrl${baseUrl.contains('?') ? '&' : '?'}current_page=${params.page}"
        : baseUrl;

    final response = await dio.get(fetchUrl);

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

    final String html;
    final List<String> liItems;
    final int totalPage;

    if (params.type == "list") {
      // ── 列表模式：提取 <li> + 解析 paginator ──
      final pagination = dom.querySelectorAll('div.paginator a');

      if (pagination.isNotEmpty) {
        final lastText = pagination.last.text;
        totalPage = int.tryParse(lastText) ?? 1;
      } else {
        totalPage = 1;
      }

      liItems = dom.querySelectorAll('li').map((li) {
        li.attributes['class'] = 'shared-li';
        return li.outerHtml;
      }).toList();

      console.i('Rust Daily 列表模式：共 $liItems 条 <li>，总页数 $totalPage');

      html =
          '''
<div style="padding:16px">
${liItems.join('\n')}
</div>''';
    } else {
      // ── 详情模式：提取 detail-body ──
      final element = dom.querySelector('div.detail-body');
      html =
          '''
<div style="padding:16px">
${element?.outerHtml ?? '暂无内容'}
</div>''';
      liItems = [];
      totalPage = 1;
    }

    return RustDailyPageData(
      html: html,
      liItems: liItems,
      totalPage: totalPage,
      currentPage: params.page,
    );
  }
}

/// Provider 参数。
class RustDailyParams {
  final String url;
  final String type;
  final int page;

  /// Tab 标识，用于区分不同 tab 的 provider 实例缓存。
  ///
  /// 即使两个 tab 使用了相同 URL，只要 [tabKey] 不同，
  /// [RustDailyParams] 就会被视为不同的 provider key。
  final String tabKey;

  const RustDailyParams({
    required this.url,
    required this.type,
    this.page = 1,
    this.tabKey = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RustDailyParams &&
          url == other.url &&
          type == other.type &&
          page == other.page &&
          tabKey == other.tabKey;

  @override
  int get hashCode => Object.hash(url, type, page, tabKey);
}

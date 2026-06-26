import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:html/parser.dart' show parse;
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/presentation/providers/init/dio_provider.dart';
import 'package:rohos_app/core/utils/logger.dart';

part 'rust_daily_provider.g.dart';

/// Rust Daily 数据 Provider。
///
/// 根据 [url]、[type] 获取并解析 HTML。
/// - type == "list" 时内部维护 _currentPage/_accumulatedItems，
///   支持 [refresh]() 和 [loadMore]() 分页操作，自动累积跨页数据到 state.html
/// - type == "detail" 时直接获取 `div.detail-body` 内容
@riverpod
class RustDaily extends _$RustDaily {
  // ── 内部分页状态（单次 fetch 内维持） ──
  int _currentPage = 1;
  int _totalPage = 1;
  final List<String> _accumulatedItems = [];

  @override
  RustDailyPageData build(RustDailyParams params) {
    return RustDailyPageData.empty();
  }

  /// 单次加载（详情页使用）：不重置分页状态，直接获取当前 URL 内容。
  Future<void> fetch() async {
    await _fetch();
  }

  /// 下拉刷新：重置到第 1 页并重新加载。
  Future<void> refresh() async {
    _currentPage = 1;
    _totalPage = 1;
    _accumulatedItems.clear();
    await _fetch();
  }

  /// 上拉加载更多：翻页并获取下一页数据，自动追加到累积列表。
  Future<void> loadMore() async {
    if (_currentPage >= _totalPage) return;
    _currentPage++;
    await _fetch();
  }

  /// 获取当前页数据（内部方法）。
  Future<void> _fetch() async {
    state = state.copyWith(loading: true);
    final dio = ref.read(dioClientProvider).dio;

    final baseUrl = params.url.startsWith("http")
        ? params.url
        : "https://rustcc.cn${params.url}";

    // list 类型时追加分页参数（根据 URL 是否已有 query string 决定 ? 或 &）
    final fetchUrl = params.type == "list"
        ? "$baseUrl${baseUrl.contains('?') ? '&' : '?'}current_page=$_currentPage"
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

    if (params.type == "list") {
      // ── 列表模式：解析 li + 累积到 _accumulatedItems ──
      final pagination = dom.querySelectorAll('div.paginator a');

      if (pagination.isNotEmpty) {
        final lastText = pagination.last.text;
        _totalPage = int.tryParse(lastText) ?? 1;
      } else {
        _totalPage = 1;
      }

      final liItems = dom.querySelectorAll('li').map((li) {
        li.attributes['class'] = 'shared-li';
        return li.outerHtml;
      }).toList();

      iLogger.i('Rust Daily 列表模式：共 ${liItems.length} 条 <li>，总页数 $_totalPage');

      // 第 1 页替换，后续页追加
      if (_currentPage == 1) {
        _accumulatedItems
          ..clear()
          ..addAll(liItems);
      } else {
        _accumulatedItems.addAll(liItems);
      }

      final html =
          '<div style="padding:16px">\n${_accumulatedItems.join('\n')}\n</div>';

      state = state.copyWith(
        loading: false,
        html: html,
        liItems: List.of(_accumulatedItems),
        totalPage: _totalPage,
        currentPage: _currentPage,
      );
    } else {
      // ── 详情模式：提取 detail-body ──
      final element = dom.querySelector('div.detail-body');
      final html =
          '<div style="padding:16px">\n${element?.outerHtml ?? '暂无内容'}\n</div>';

      state = state.copyWith(
        loading: false,
        html: html,
        liItems: [],
        totalPage: 1,
        currentPage: 1,
      );
    }
  }
}

/// Provider 参数（不含 page，一个 (url+type+tabKey) 对应一个 provider 实例）。
class RustDailyParams {
  final String url;
  final String type; // "list" | "detail"

  /// Tab 标识，用于区分不同 tab 的 provider 实例缓存。
  ///
  /// 即使两个 tab 使用了相同 URL，只要 [tabKey] 不同，
  /// [RustDailyParams] 就会被视为不同的 provider key。
  final String tabKey;

  const RustDailyParams({
    required this.url,
    required this.type,
    this.tabKey = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RustDailyParams &&
          url == other.url &&
          type == other.type &&
          tabKey == other.tabKey;

  @override
  int get hashCode => Object.hash(url, type, tabKey);
}

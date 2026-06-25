import 'detail_item.dart';

/// 详情分页累积状态。
///
/// 由 [DetailPageAccumulator] provider 管理，追踪已加载的所有详情项、
/// 当前页号、分页元数据等。UI 通过 [hasMore] 判断是否还有更多页。
class DetailAccumulatorState {
  /// 累积的所有详情项。
  final List<DetailItem> items;

  /// 已加载到的页码（0 = 尚未开始加载）。
  final int currentPage;

  /// 总页数（来自最近一次响应），null 表示未提供。
  final int? totalPage;

  /// 下一页 URL（来自最近一次响应），null 表示未提供或无下一页。
  final String? nextPageUrl;

  /// 最近一次加载的 URL，用于构造下一页请求。
  final String? lastLoadedUrl;

  /// 当前是否正在加载中。
  final bool isLoading;

  /// 最近一次加载的错误。
  final Object? error;

  /// 是否至少成功加载过一次。
  final bool hasLoaded;

  const DetailAccumulatorState({
    required this.items,
    required this.currentPage,
    this.totalPage,
    this.nextPageUrl,
    this.lastLoadedUrl,
    required this.isLoading,
    this.error,
    required this.hasLoaded,
  });

  /// 初始空状态。
  factory DetailAccumulatorState.empty() => const DetailAccumulatorState(
        items: [],
        currentPage: 0,
        totalPage: null,
        nextPageUrl: null,
        lastLoadedUrl: null,
        isLoading: false,
        error: null,
        hasLoaded: false,
      );

  /// 是否还有更多分页数据。
  /// items 为空时返回 true（尚未加载，需要尝试），
  /// 否则根据 nextPageUrl 或 totalPage 判断。
  bool get hasMore {
    if (items.isEmpty) return true;
    if (nextPageUrl != null) return true;
    if (totalPage != null && currentPage < totalPage!) return true;
    return false;
  }

  /// 带字段复制的便捷方法。
  DetailAccumulatorState copyWith({
    List<DetailItem>? items,
    int? currentPage,
    int? totalPage,
    String? nextPageUrl,
    String? lastLoadedUrl,
    bool? isLoading,
    Object? error,
    bool? hasLoaded,
    bool clearError = false,
  }) =>
      DetailAccumulatorState(
        items: items ?? this.items,
        currentPage: currentPage ?? this.currentPage,
        totalPage: totalPage ?? this.totalPage,
        nextPageUrl: nextPageUrl ?? this.nextPageUrl,
        lastLoadedUrl: lastLoadedUrl ?? this.lastLoadedUrl,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        hasLoaded: hasLoaded ?? this.hasLoaded,
      );
}

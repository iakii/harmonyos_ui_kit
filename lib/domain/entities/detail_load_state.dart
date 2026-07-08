import 'detail_item.dart';

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
  }) => DetailLoadState(
    items: items,
    isLoading: false,
    isComplete: true,
    batchCount: batchCount,
    totalPage: totalPage,
    nextPageUrl: nextPageUrl,
    current: current,
  );
}

import 'detail_item.dart';

/// 详情加载状态（渐进式）。
class DetailLoadState {
  final List<DetailItem> items;
  final bool isLoading;
  final bool isComplete;
  final String? error;
  final int batchCount;

  const DetailLoadState({
    required this.items,
    required this.isLoading,
    required this.isComplete,
    this.error,
    this.batchCount = 0,
  });

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
  }) => DetailLoadState(
    items: items,
    isLoading: false,
    isComplete: true,
    batchCount: batchCount,
  );
}

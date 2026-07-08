import 'gallery_item.dart';

/// 图集分页累积状态。
///
/// 由 [GalleryPageAccumulator] provider 管理，替代原来散落在
/// [ConsumerState] 中的 [_currentPage]、[_totalPage] 等可变字段。
/// 使用场景见 `gallery_page.dart`。
class GalleryAccumulatorState {
  /// 累积的所有图集项。
  final List<GalleryItem> items;

  /// 已加载到的页码（0 = 尚未开始加载）。
  final int currentPage;

  /// 总页数（从最近一次返回数据中获取）。
  final int totalPage;

  /// 当前是否正在加载中。
  final bool isLoading;

  /// 最近一次加载的错误（仅保留最近一次，加载成功时置 null）。
  final Object? error;

  /// 是否至少成功加载过一次（用于区分"未加载"和"确实无数据"）。
  final bool hasLoaded;

  const GalleryAccumulatorState({
    required this.items,
    required this.currentPage,
    required this.totalPage,
    required this.isLoading,
    this.error,
    required this.hasLoaded,
  });

  /// 初始空状态。
  factory GalleryAccumulatorState.empty() => const GalleryAccumulatorState(
    items: [],
    currentPage: 0,
    totalPage: 0,
    isLoading: false,
    error: null,
    hasLoaded: false,
  );

  /// 是否还有更多页可加载。
  bool get hasMore => items.isEmpty || currentPage < totalPage;

  /// 带字段复制的便捷方法。
  GalleryAccumulatorState copyWith({
    List<GalleryItem>? items,
    int? currentPage,
    int? totalPage,
    bool? isLoading,
    Object? error,
    bool? hasLoaded,
  }) => GalleryAccumulatorState(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    totalPage: totalPage ?? this.totalPage,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    hasLoaded: hasLoaded ?? this.hasLoaded,
  );
}

/// Rust Daily 页面分页数据。
class RustDailyPageData {
  /// 解析后的完整 HTML（数字分页模式使用）。
  final String html;

  /// 解析后的 li 条目列表（无限滚动模式使用，逐条累积）。
  final List<String> liItems;

  /// 总页数。
  final int totalPage;

  /// 当前页码。
  final int currentPage;

  final bool loading;

  const RustDailyPageData({
    required this.html,
    required this.liItems,
    required this.totalPage,
    required this.currentPage,
    required this.loading,
  });

  bool get hasMore => currentPage < totalPage;

  factory RustDailyPageData.empty() {
    return RustDailyPageData(
      html: '',
      liItems: [],
      totalPage: 1,
      currentPage: 1,
      loading: false,
    );
  }

  RustDailyPageData copyWith({
    String? html,
    List<String>? liItems,
    int? totalPage,
    int? currentPage,
    bool? loading,
  }) {
    return RustDailyPageData(
      html: html ?? this.html,
      liItems: liItems ?? this.liItems,
      totalPage: totalPage ?? this.totalPage,
      currentPage: currentPage ?? this.currentPage,
      loading: loading ?? this.loading,
    );
  }
}

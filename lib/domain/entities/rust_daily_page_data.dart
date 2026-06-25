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

  const RustDailyPageData({
    required this.html,
    required this.liItems,
    required this.totalPage,
    required this.currentPage,
  });

  bool get hasMore => currentPage < totalPage;
}

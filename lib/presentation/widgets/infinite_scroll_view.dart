import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';
import 'package:rohos_app/presentation/widgets/scrollbar.dart'
    show CustomScrollBehaviour;

/// 无限滚动视图控制器，封装 [RefreshController] 的公开方法。
///
/// 由外部创建并通过 [InfiniteScrollView.viewController] 传入，
/// 用于在 InfiniteScrollView 外部手动触发刷新/加载动画。
class InfiniteScrollViewController {
  RefreshController? _refreshController;

  /// 由 [InfiniteScrollView] 内部调用，绑定实际的 [RefreshController]。
  void _bind(RefreshController controller) {
    _refreshController = controller;
  }

  /// 触发下拉刷新。
  void requestRefresh({bool needMove = true}) {
    _refreshController?.requestRefresh(needMove: needMove);
  }

  /// 标记刷新完成。
  void refreshCompleted() {
    _refreshController?.refreshCompleted();
  }

  /// 标记刷新失败。
  void refreshFailed() {
    _refreshController?.refreshFailed();
  }

  /// 标记加载完成（上拉加载更多）。
  void loadComplete() {
    _refreshController?.loadComplete();
  }

  /// 标记加载失败。
  void loadFailed() {
    _refreshController?.loadFailed();
  }

  /// 标记没有更多数据。
  void loadNoData() {
    _refreshController?.loadNoData();
  }

  /// 重置无数据状态（恢复允许加载更多）。
  void resetNoData() {
    _refreshController?.resetNoData();
  }
}

/// 无限滚动列表视图。
///
/// 提供两种模式：
/// - 默认构造（[InfiniteScrollView]）：基于 [children] 的简单列表，刷新/加载状态由外部管理
/// - [InfiniteScrollView.paginated]：自包含分页模式，内部管理 [RefreshController] 和
///   SmartRefresher 状态转换，外部通过 [onRefresh]/[onLoadMore] 异步回调驱动数据加载
enum _InfiniteScrollMode { children, paginated }

class InfiniteScrollView extends StatefulWidget {
  // ═══════════════════════════════════════════════════════════════
  // 模式标记
  // ═══════════════════════════════════════════════════════════════

  final _InfiniteScrollMode _mode;

  // ═══════════════════════════════════════════════════════════════
  // 通用参数
  // ═══════════════════════════════════════════════════════════════

  /// 下拉刷新回调（异步，内部 await 完成后自动调 refreshCompleted）。
  final Future<void> Function() onRefresh;

  /// 是否还有更多页可加载。
  final bool hasMore;

  /// 外部 [ScrollController]，用于共享滚动位置。
  final ScrollController? controller;

  // ═══════════════════════════════════════════════════════════════
  // children 模式参数（旧版，向后兼容）
  // ═══════════════════════════════════════════════════════════════

  /// 列表子组件（children 模式）。
  final List<Widget>? children;

  /// 当前是否正在加载更多（children 模式，由外部管理）。
  final bool isLoadingMore;

  /// 外部 [RefreshController]（children 模式，由外部创建管理）。
  final RefreshController? refreshController;

  /// 初始化时是否自动触发下拉刷新（children 模式）。
  final bool autoRequestRefresh;

  /// 外部控制器，用于手动触发刷新/加载动画。
  final InfiniteScrollViewController? viewController;

  // ═══════════════════════════════════════════════════════════════
  // paginated 模式参数（新版，自包含分页）
  // ═══════════════════════════════════════════════════════════════

  /// 列表项数量（paginated 模式）。
  final int? itemCount;

  /// 列表项构造器（paginated 模式）。
  final IndexedWidgetBuilder? itemBuilder;

  /// 当前错误（paginated 模式，null 表示无错误）。
  final Object? error;

  /// 列表头部组件（paginated 模式，固定显示在列表上方）。
  final List<Widget>? headerItems;

  /// 列表底部组件（paginated 模式，固定显示在列表下方）。
  final List<Widget>? footerItems;

  /// 内容区域构建器（paginated 模式）。
  ///
  /// 接收 [itemBuilder] 和 [itemCount]，返回一个 Widget 作为内容 sliver。
  /// 不设置时默认用 [SliverToBoxAdapter] 逐项包裹。
  /// 可用于注入 [SliverStaggeredGrid]、[SliverGrid] 等自定义布局。
  final Widget Function(IndexedWidgetBuilder, int)? contentSliverBuilder;

  /// 初始化时是否自动加载第一页（paginated 模式，默认 true）。
  final bool autoLoad;

  // ═══════════════════════════════════════════════════════════════
  // 异步加载更多（paginated 模式）
  // ═══════════════════════════════════════════════════════════════

  /// children 模式同步加载更多回调（旧版）。
  final void Function()? _onLoadMoreVoid;

  /// paginated 模式异步加载更多回调（新版）。
  final Future<void> Function()? _onLoadMoreAsync;

  // ═══════════════════════════════════════════════════════════════
  // 构造器：children 模式（旧版，向后兼容）
  // ═══════════════════════════════════════════════════════════════

  /// 基于 [children] 的简单列表模式。
  ///
  /// 刷新/加载状态由外部管理，通过 [refreshController]、[isLoadingMore]、
  /// [autoRequestRefresh] 参数控制。适用于需要完全控制 SmartRefresher 状态的场景。
  const InfiniteScrollView({
    super.key,
    required this.children,
    required this.onRefresh,
    required this.hasMore,
    this.isLoadingMore = false,
    this.controller,
    this.refreshController,
    this.autoRequestRefresh = true,
    this.viewController,
    required void Function() onLoadMore,
  }) : _mode = _InfiniteScrollMode.children,
       _onLoadMoreVoid = onLoadMore,
       _onLoadMoreAsync = null,
       itemCount = null,
       itemBuilder = null,
       error = null,
       headerItems = null,
       footerItems = null,
       contentSliverBuilder = null,
       autoLoad = true;

  // ═══════════════════════════════════════════════════════════════
  // 构造器：paginated 模式（自包含分页）
  // ═══════════════════════════════════════════════════════════════

  /// 自包含分页模式。
  ///
  /// 内部管理 [RefreshController] 和 SmartRefresher 状态转换。
  /// 外部只需提供：
  /// - [onRefresh] — 下拉刷新回调（异步）
  /// - [onLoadMore] — 上拉加载更多回调（异步，内部 await 完成后自动处理 SmartRefresher 状态）
  /// - [itemCount] / [itemBuilder] — 列表项数据
  /// - [hasMore] — 是否还有更多页
  ///
  /// 可选：[error] 控制错误显示，[headerItems]/[footerItems] 添加固定组件，
  /// [contentSliverBuilder] 注入自定义 sliver 布局（如 [SliverStaggeredGrid]）。
  const InfiniteScrollView.paginated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required Future<void> Function() onLoadMore,
    required this.onRefresh,
    required this.hasMore,
    this.error,
    this.headerItems = const [],
    this.footerItems = const [],
    this.controller,
    this.contentSliverBuilder,
    this.autoLoad = true,
    this.viewController,
  }) : _mode = _InfiniteScrollMode.paginated,
       _onLoadMoreAsync = onLoadMore,
       _onLoadMoreVoid = null,
       children = null,
       isLoadingMore = false,
       refreshController = null,
       autoRequestRefresh = false;

  @override
  State<InfiniteScrollView> createState() => _InfiniteScrollViewState();
}

class _InfiniteScrollViewState extends State<InfiniteScrollView>
    with WidgetsBindingObserver {
  // ── 控制器（paginated 模式内部使用） ──
  late final RefreshController _refreshController;
  late final ScrollController _scrollController;
  bool _isInternalController = false;
  bool _isInternalRefreshController = false;

  // ── 生命周期状态 ──
  bool _isPaused = false;
  bool _disposed = false;

  // ═══════════════════════════════════════════════════════════════
  // 生命周期
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget._mode == _InfiniteScrollMode.paginated) {
      // paginated 模式：内部创建 RefreshController
      _refreshController = RefreshController();
      _isInternalRefreshController = true;
      _scrollController = widget.controller ?? ScrollController();
      _isInternalController = widget.controller == null;

      if (widget.autoLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshController.requestRefresh(needMove: false);
        });
      }
    } else {
      // children 模式：使用外部传入或内部创建
      _refreshController = widget.refreshController ?? RefreshController();
      _isInternalRefreshController = widget.refreshController == null;
      _scrollController = widget.controller ?? ScrollController();
      _isInternalController = widget.controller == null;

      if (widget.autoRequestRefresh) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshController.requestRefresh(needMove: false);
        });
      }
    }

    // 绑定外部 viewController 到内部 _refreshController
    widget.viewController?._bind(_refreshController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    if (_isInternalRefreshController) _refreshController.dispose();
    if (_isInternalController) _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isPaused = true;
      case AppLifecycleState.resumed:
        _isPaused = false;
      case AppLifecycleState.hidden:
        _isPaused = true;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didUpdateWidget(InfiniteScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget._mode == _InfiniteScrollMode.paginated) {
      // paginated 模式：检测 itemCount 从>0→0（URL 变化触发重置）
      if ((oldWidget.itemCount ?? 0) > 0 && (widget.itemCount ?? 0) == 0) {
        _refreshController.resetNoData();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshController.requestRefresh(needMove: false);
        });
      }
    } else {
      // children 模式：保持旧版兼容
      if (oldWidget.isLoadingMore && !widget.isLoadingMore) {
        _finishLoad();
      }

      if (oldWidget.controller != widget.controller) {
        if (_isInternalController) _scrollController.dispose();
        if (widget.controller != null) {
          _scrollController = widget.controller!;
          _isInternalController = false;
        } else {
          _scrollController = ScrollController();
          _isInternalController = true;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 刷新 / 加载
  // ═══════════════════════════════════════════════════════════════

  Future<void> _onRefresh() async {
    if (_disposed || _isPaused) return;

    try {
      await widget.onRefresh();
      if (!mounted || _disposed) return;
      _refreshController.refreshCompleted();
      if (!widget.hasMore) {
        _refreshController.loadNoData();
      } else {
        _refreshController.resetNoData();
      }
    } catch (_) {
      if (!mounted || _disposed) return;
      _refreshController.refreshFailed();
    }
  }

  Future<void> _onLoading() async {
    if (_disposed || _isPaused) return;

    if (widget._mode == _InfiniteScrollMode.paginated) {
      // paginated 模式：异步加载，完成后自动管理状态
      if (!widget.hasMore) {
        _refreshController.loadNoData();
        return;
      }
      try {
        await widget._onLoadMoreAsync!();
        if (!mounted || _disposed) return;
        if (widget.hasMore) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      } catch (_) {
        if (!mounted || _disposed) return;
        _refreshController.loadFailed();
      }
    } else {
      // children 模式：保持旧版兼容，fire-and-forget 触发加载
      if (!widget.hasMore) {
        _refreshController.loadNoData();
        return;
      }
      widget._onLoadMoreVoid?.call();
      // isLoadingMore → true 后，didUpdateWidget 在 loadingMore 回退时调 _finishLoad
    }
  }

  void _finishLoad() {
    if (_disposed || !mounted) return;
    if (!widget.hasMore) {
      _refreshController.loadNoData();
    } else {
      _refreshController.loadComplete();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 构建
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final accentColor = theme.accentColor;
    final textStyle = theme.typography.caption?.copyWith(
      fontSize: 14,
      color: accentColor,
    );

    if (widget._mode == _InfiniteScrollMode.paginated) {
      return _buildPaginated(accentColor, textStyle);
    }
    return _buildChildren(accentColor, textStyle);
  }

  /// paginated 模式：内部管理 RefreshController，列表数据由 itemBuilder 驱动。
  Widget _buildPaginated(Color accentColor, TextStyle? textStyle) {
    final items = List.generate(
      widget.itemCount ?? 0,
      (i) => widget.itemBuilder!(context, i),
    );

    final slivers = <Widget>[];
    // 头部组件（headerItems）
    if (widget.headerItems != null) {
      for (final item in widget.headerItems!) {
        slivers.add(SliverToBoxAdapter(child: item));
      }
    }

    if (widget.contentSliverBuilder != null) {
      // 自定义 sliver 布局（如 SliverStaggeredGrid）
      slivers.add(
        widget.contentSliverBuilder!(
          widget.itemBuilder!,
          widget.itemCount ?? 0,
        ),
      );
    } else {
      // 列表布局
      for (final item in items) {
        slivers.add(SliverToBoxAdapter(child: item));
      }
    }

    // 底部组件（footerItems）
    if (widget.footerItems != null) {
      for (final item in widget.footerItems!) {
        slivers.add(SliverToBoxAdapter(child: item));
      }
    }

    return _buildScaffold(accentColor, textStyle, slivers);
  }

  /// children 模式：保持旧版兼容，直接渲染外部传入的 children。
  Widget _buildChildren(Color accentColor, TextStyle? textStyle) {
    // 在 children 模式下，没有 GridDelegate，直接使用 ListView
    final slivers = (widget.children ?? [])
        .map((child) => SliverToBoxAdapter(child: child))
        .toList();

    return _buildScaffold(accentColor, textStyle, slivers);
  }

  /// 共享的 SmartRefresher 脚手架。
  Widget _buildScaffold(
    Color accentColor,
    TextStyle? textStyle,
    List<Widget> slivers,
  ) {
    return ScrollConfiguration(
      behavior: CustomScrollBehaviour(),
      child: RefreshConfiguration(
        // hideFooterWhenNotFull: true,
        enableLoadingWhenFailed: true,
        enableBallisticRefresh: true,
        enableScrollWhenRefreshCompleted: true,
        maxUnderScrollExtent: 0,
        springDescription: const SpringDescription(
          stiffness: 170,
          damping: 16,
          mass: 1.9,
        ),
        enableBallisticLoad: true,
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: true,
          header: _buildHeader(accentColor, textStyle),
          footer: _buildFooter(accentColor, textStyle),
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: slivers,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, TextStyle? textStyle) {
    return ClassicHeader(
      textStyle: textStyle ?? const TextStyle(color: Colors.grey),
      idleText: '下拉刷新',
      releaseText: '松开刷新',
      refreshingText: '刷新中...',
      completeText: '刷新完成',
      failedText: '刷新失败',
      idleIcon: Icon(HMIcons.chevronDown, color: accentColor),
      releaseIcon: Icon(HMIcons.arrowClockwise, color: accentColor),
      refreshingIcon: Loading(size: 32, color: accentColor),
      completeIcon: Icon(HMIcons.checkmarkCircle, size: 24, color: accentColor),
      failedIcon: Icon(HMIcons.exclamationmarkCircle, color: accentColor),
      spacing: 8,
    );
  }

  Widget _buildFooter(Color accentColor, TextStyle? textStyle) {
    return ClassicFooter(
      textStyle: textStyle ?? const TextStyle(color: Colors.grey),
      loadStyle: LoadStyle.ShowWhenLoading,
      idleText: '加载完成',
      loadingText: '加载更多...',
      canLoadingText: '释放加载',
      canLoadingIcon: Icon(HMIcons.chevronUp, color: accentColor),
      noDataText: '— 已加载全部 —',
      failedText: '加载失败',
      loadingIcon: Loading(size: 32, color: accentColor),
      noMoreIcon: const SizedBox.shrink(),
      spacing: 8,
      idleIcon: Icon(HMIcons.checkmarkCircle, color: accentColor),
    );
  }
}

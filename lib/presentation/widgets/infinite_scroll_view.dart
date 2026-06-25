import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rohos_app/presentation/widgets/loading.dart';
import 'package:rohos_app/presentation/widgets/scrollbar.dart' show CustomScrollBehaviour;

/// 无限滚动列表视图。
///
/// 基于 [SmartRefresher] 封装下拉刷新和上拉加载更多，自带应用生命周期管理。
class InfiniteScrollView extends StatefulWidget {
  const InfiniteScrollView({
    super.key,
    required this.children,
    required this.onRefresh,
    required this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.controller,
    this.refreshController,
  });

  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  /// 外部传入的 [ScrollController]，用于共享滚动位置。
  final ScrollController? controller;

  /// 外部传入的 [RefreshController]，用于外部控制刷新/加载状态。
  ///
  /// 若为 `null`，由组件内部自行创建和管理生命周期。
  final RefreshController? refreshController;

  @override
  State<InfiniteScrollView> createState() => _InfiniteScrollViewState();
}

class _InfiniteScrollViewState extends State<InfiniteScrollView>
    with WidgetsBindingObserver {
  // ── 控制器 ──
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

    if (widget.refreshController != null) {
      _refreshController = widget.refreshController!;
    } else {
      _refreshController = RefreshController();
      _isInternalRefreshController = true;
    }
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _isInternalController = true;
    }
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

    // isLoadingMore: true → false → 数据到达，完成上拉
    if (oldWidget.isLoadingMore && !widget.isLoadingMore) {
      _finishLoad();
    }

    // 外部 controller 切换
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

    if (!widget.hasMore) {
      _refreshController.loadNoData();
      return;
    }
    widget.onLoadMore();
    // isLoadingMore → true，didUpdateWidget 将在数据到达后调用 _finishLoad
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

    return ScrollConfiguration(
      behavior: CustomScrollBehaviour(),
      child: RefreshConfiguration(
        hideFooterWhenNotFull: true,
        enableLoadingWhenFailed: true,
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
          child: ListView(
            controller: _scrollController,
            children: widget.children,
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
      refreshingIcon: Loading(size: 24, color: accentColor),
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
      noDataText: '— 已加载全部 —',
      failedText: '加载失败',
      loadingIcon: Loading(size: 24, color: accentColor),
      noMoreIcon: const SizedBox.shrink(),
      spacing: 8,
      idleIcon: Icon(HMIcons.checkmarkCircle, color: accentColor),
    );
  }
}

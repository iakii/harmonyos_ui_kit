import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../models/plugin/gallery_item.dart';
import '../../providers/js/detail_provider.dart';

/// 图集详情页。
///
/// 通过 meitule.js 的 getDetails 在后台线程获取图片详情列表，
/// 利用 JS 端 __postMessage('sendChannelDetails', ...) 的进度消息
/// 逐步展示数据，最后展示完整结果。
class DetailPage extends HookConsumerWidget {
  const DetailPage({super.key, required this.url});

  /// 图集详情链接（从 GoRouter state.extra 传入）。
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(detailLoadProvider(url));
    final theme = HarmonyTheme.of(context);

    return HosPage(
      leading: const BackIcon(),
      title: '详情',
      backgroundColor: HarmonyTheme.of(context).surfaceColor,
      showAppBar: true,
      body: asyncState.when(
        loading: () => _LoadingWidget(theme: theme),
        error: (err, _) =>
            HosErrorState(message: err.toString(), onRetry: null),
        data: (state) => _buildBody(context, theme, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HarmonyThemeData theme,
    DetailLoadState state,
  ) {
    // 错误状态
    if (state.error != null) {
      return HosErrorState(message: state.error!, onRetry: null);
    }

    // 加载中（可能有部分数据）
    if (state.isLoading) {
      return Column(
        children: [
          // 进度指示
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  state.items.isNotEmpty
                      ? '已加载 ${state.items.length} 项（第 ${state.batchCount} 批）'
                      : '正在加载...',
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
          // 已加载的部分数据
          if (state.items.isNotEmpty)
            Expanded(child: _DetailList(items: state.items)),
        ],
      );
    }

    // 加载完成
    if (state.isComplete) {
      if (state.items.isEmpty) {
        return const HosEmptyState(message: '暂无内容');
      }
      return _DetailList(items: state.items);
    }

    return const SizedBox.shrink();
  }
}

/// 加载中（无数据）。
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({required this.theme});

  final HarmonyThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HosLoading(),
          const SizedBox(height: 16),
          Text('正在初始化...', style: theme.typography.caption),
        ],
      ),
    );
  }
}

/// 详情列表。
class _DetailList extends StatelessWidget {
  const _DetailList({required this.items});

  final List<DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _DetailCard(item: items[index], index: index, total: items.length),
    );
  }
}

/// 单张详情卡片。
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.item,
    required this.index,
    required this.total,
  });

  final DetailItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HosCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.cover != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  item.cover!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: theme.surfaceColor,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: theme.surfaceColor,
                      child: const Center(child: HosLoading()),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title != null)
                    Text(item.title!, style: theme.typography.body),
                  if (item.href != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.href!,
                      style: theme.typography.caption?.copyWith(
                        color: theme.accentColor.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  HosOutlinedButton(
                    onPressed: () {},
                    child: Text(
                      'Index: ${index + 1} / $total',
                      style: theme.typography.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

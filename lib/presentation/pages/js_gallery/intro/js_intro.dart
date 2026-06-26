import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/extensions/numbric_ext.dart' show ExtensionNum;

import 'package:rohos_app/domain/entities/detail_item.dart' show DetailItem;
import 'package:rohos_app/presentation/providers/js_gallery/intro_provider.dart'
    show IntroData, jsIntroProvider;
import 'package:rohos_app/presentation/widgets/loading.dart'
    show Loading, imageLoadState;

/// 漫画简介页面。
///
/// 展示漫画封面、基本信息（作者/分类/状态）、标签、简介以及章节列表。
/// 标题栏优先显示传入的 title 参数，若为空则 fallback 到漫画名。
class JsIntroPage extends ConsumerStatefulWidget {
  const JsIntroPage({super.key, required this.url, this.title = '简介'});

  /// 漫画详情链接（从 GoRouter state.extra 传入）。
  final String url;

  /// 页面标题（从 GoRouter state.extra 传入，可选）。
  final String title;

  @override
  ConsumerState<JsIntroPage> createState() => _JsIntroPageState();
}

class _JsIntroPageState extends ConsumerState<JsIntroPage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(jsIntroProvider(widget.url).notifier).refresh();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final data = ref.watch(jsIntroProvider(widget.url));

    // ── 根据加载状态决定 body ──
    Widget body;
    if (_isLoading) {
      body = const Center(child: Loading(size: 64));
    } else if (_error != null) {
      body = HosErrorState(message: _error!, onRetry: _loadData);
    } else if (data.title.isEmpty && data.list.isEmpty) {
      body = const HosEmptyState(message: '暂无简介信息');
    } else {
      body = _buildContent(context, theme, data);
    }

    return HosPage(
      showAppBar: true,
      title: data.title.isNotEmpty ? data.title : widget.title,
      leading: const BackIcon(),
      body: body,
    );
  }

  // ── 正文内容：封面 → 标题 → 信息卡片 → 标签 → 简介 → 章节列表 ──

  Widget _buildContent(
    BuildContext context,
    HarmonyThemeData theme,
    IntroData data,
  ) {
    return ListView(
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      children: [
        // 封面图
        if (data.cover.isNotEmpty)
          ExtendedImage.network(
            data.cover,
            fit: BoxFit.fitWidth,
            headers: {'referer': data.cover, 'referrerpolicy': 'unsafe-url'},
            handleLoadingProgress: true,
            loadStateChanged: imageLoadState,
          ),

        // 漫画标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            data.title,
            style: theme.typography.title2?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 基本信息卡片（作者/分类/状态）
        HosCard(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Column(
            children: [
              _infoRow(theme, '作者', data.author),
              Divider(height: 1, color: theme.dividerColor),
              _infoRow(theme, '分类', data.category),
              Divider(height: 1, color: theme.dividerColor),
              _infoRow(theme, '状态', data.status),
            ],
          ),
        ),

        // 标签 chips
        if (data.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: data.tags.map((tag) => _tagChip(theme, tag)).toList(),
            ),
          ),

        // 简介
        if (data.description.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('简介', style: theme.typography.title3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              data.description,
              style: theme.typography.body?.copyWith(height: 1.6),
            ),
          ),
        ],

        // 章节列表
        if (data.list.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              '章节列表（共 ${data.list.length} 话）',
              style: theme.typography.title3,
            ),
          ),
          ...data.list.map((ch) => _chapterItem(context, theme, ch)),
        ],
      ],
    );
  }

  // ── 信息行（作者/分类/状态） ──

  Widget _infoRow(HarmonyThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Text(
            label,
            style: theme.typography.bodySmall?.copyWith(
              color: theme.textSecondaryColor,
            ),
          ),
          // const SizedBox(width: 16),
          16.H,
          Expanded(child: Text(value, style: theme.typography.body)),
        ],
      ),
    );
  }

  // ── 标签 chip（复用 grid_item_card 的样式） ──

  Widget _tagChip(HarmonyThemeData theme, DetailItem tag) {
    return InkWell(
      onTap: () {
        if (tag.href == null || tag.href!.isEmpty) return;
        context.push(
          '/js_gallery_list',
          extra: {'title': tag.title ?? '', 'url': tag.href ?? ''},
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag.title ?? '',
          style: theme.typography.overline?.copyWith(
            fontSize: 12,
            color: theme.accentColor.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  // ── 章节列表项 ──

  Widget _chapterItem(
    BuildContext context,
    HarmonyThemeData theme,
    DetailItem chapter,
  ) {
    return HosListItem(
      title: chapter.title ?? '',
      trailing: Icon(Icons.chevron_right, color: theme.textSecondaryColor),
      onTap: () {
        if (chapter.href == null || chapter.href!.isEmpty) return;
        context.push(
          '/js_gallery_detail',
          extra: {'title': chapter.title ?? '', 'url': chapter.href ?? ''},
        );
      },
    );
  }
}

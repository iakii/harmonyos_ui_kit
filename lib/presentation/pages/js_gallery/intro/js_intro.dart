import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/extensions/numbric_ext.dart' show ExtensionNum;

import 'package:rohos_app/domain/entities/detail_item.dart' show DetailItem;
import 'package:rohos_app/router_args.dart';
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
  bool _descExpanded = false; // 简介展开/收起状态

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
        // 封面图 — Hero 区域，带底部渐变遮罩与顶部圆角
        if (data.cover.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 600,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExtendedImage.network(
                    data.cover,
                    fit: BoxFit.cover,
                    headers: {
                      'referer': data.cover,
                      'referrerpolicy': 'unsafe-url',
                    },
                    handleLoadingProgress: true,
                    loadStateChanged: imageLoadState,
                  ),
                  // 底部渐变遮罩，使封面平滑过渡到页面背景
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.scaffoldBackgroundColor.withValues(
                              alpha: 0.85,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 漫画标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            data.title,
            style: theme.typography.title1?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'HarmonyOs Sans SC',
            ),
          ),
        ),

        // 基本信息卡片（作者/分类/状态）
        HosCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _infoRow(theme, Icons.person_outline, '作者', data.author),
              HosDivider(),
              _infoRow(theme, Icons.category_outlined, '分类', data.category),
              HosDivider(),
              _infoRow(
                theme,
                Icons.info_outline,
                '状态',
                data.status,
                statusColor: _statusColor(theme, data.status),
              ),
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

        // 简介 — 用 HosCard 包裹，支持展开/收起
        if (data.description.isNotEmpty)
          HosCard(child: _descriptionSection(theme, data.description)),

        // 章节列表
        if (data.list.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Text(
                  '章节列表',
                  style: theme.typography.title3?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'HarmonyOs Sans SC',
                  ),
                ),
                const Spacer(),
                Text(
                  '共 ${data.list.length} 话',
                  style: theme.typography.bodySmall?.copyWith(
                    color: theme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...data.list.asMap().entries.map(
            (entry) =>
                _chapterItem(context, theme, entry.value, index: entry.key),
          ),
        ],
      ],
    );
  }

  // ── 信息行（作者/分类/状态） ──

  /// 返回状态对应的语义色。
  Color _statusColor(HarmonyThemeData theme, String status) {
    final s = status.trim();
    if (s.contains('完结') || s.contains('完成')) {
      return theme.colorTokens.statusSuccess;
    }
    if (s.contains('连载')) {
      return theme.colorTokens.statusInfo;
    }
    return theme.textSecondaryColor;
  }

  Widget _infoRow(
    HarmonyThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.textSecondaryColor),
          8.H,
          Text(
            label,
            style: theme.typography.bodySmall?.copyWith(
              color: theme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          16.H,
          Expanded(
            child: Row(
              children: [
                // 状态颜色圆点
                if (statusColor != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  6.H,
                ],
                Text(
                  value,
                  style: theme.typography.body?.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
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
          extra: GalleryRouteArgs(title: tag.title ?? '', url: tag.href ?? ''),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          tag.title ?? '',
          style: theme.typography.overline?.copyWith(
            fontSize: 14,
            fontFamily: 'HarmonyOs Sans SC',
            color: theme.accentColor.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  // ── 简介展开/收起卡片 ──

  /// 可展开/收起的简介区。默认显示 3 行，溢出时显示展开按钮。
  Widget _descriptionSection(HarmonyThemeData theme, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '简介',
          style: theme.typography.title3?.copyWith(
            fontFamily: 'HarmonyOs Sans SC',
          ),
        ),
        8.H,
        Text(
          description,
          style: theme.typography.body?.copyWith(height: 1.6),
          maxLines: _descExpanded ? null : 3,
          overflow: _descExpanded ? null : TextOverflow.ellipsis,
        ),
        if (!_descExpanded)
          Align(
            alignment: Alignment.centerRight,
            child: HosTextButton(
              onPressed: () => setState(() => _descExpanded = true),
              child: const Text('展开'),
            ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: HosTextButton(
              onPressed: () => setState(() => _descExpanded = false),
              child: const Text('收起'),
            ),
          ),
      ],
    );
  }

  // ── 章节列表项 ──

  Widget _chapterItem(
    BuildContext context,
    HarmonyThemeData theme,
    DetailItem chapter, {
    required int index,
  }) {
    return HosListItem(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${index + 1}',
          style: theme.typography.caption?.copyWith(
            color: theme.accentColor.normal,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      title: chapter.title ?? '',

      // subtitle: index == 0 ? '最新' : null,
      trailing: Icon(Icons.chevron_right, color: theme.textSecondaryColor),
      onTap: () {
        if (chapter.href == null || chapter.href!.isEmpty) return;
        context.push(
          '/js_gallery_detail',
          extra: GalleryRouteArgs(
            title: chapter.title ?? '',
            url: chapter.href ?? '',
          ),
        );
      },
    );
  }
}

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/router_args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/domain/entities/gallery_item.dart';
import 'package:rohos_app/presentation/providers/js_gallery/plugin_info_provider.dart'
    show pluginInfoProvider;
import 'package:rohos_app/presentation/widgets/loading.dart'
    show imageLoadState;

/// 单个网格卡片：封面图 + 标题。
class GridItemCard extends ConsumerWidget {
  const GridItemCard({super.key, required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HarmonyTheme.of(context);

    final headers = ref.read(
      pluginInfoProvider.select((selector) => selector.value?.headers ?? {}),
    );
    return GestureDetector(
      onTap: () {
        // _TypeError (type '_Map<String, String>' is not a subtype of type 'GalleryRouteArgs' in type cast)
        if (item.link.isEmpty || item.to == 'none') return;
        final path = GalleryItem.getRoutePath(item.to);
        context.push(
          path,
          extra: GalleryRouteArgs(title: item.title, url: item.link),
        );
      },
      child: HosCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面图（自带 HosLoading 加载动画）
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: ExtendedImage.network(
                item.cover,
                // 'https://cdn.pixabay.com/photo/2016/05/31/11/26/baby-1426651_1280.jpg',
                fit: BoxFit.fitWidth,
                headers: {
                  "referer": item.cover,
                  "referrerpolicy": "unsafe-url",
                  ...headers,
                },
                handleLoadingProgress: true,
                // cache: false,
                loadStateChanged: imageLoadState,
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.caption?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: "HarmonyOs Sans SC",
                    ),
                  ),
                  if (item.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: item.tags
                            .map(
                              (tag) => InkWell(
                                onTap: () {
                                  if (tag.to == 'none' ||
                                      tag.href == null ||
                                      tag.href == '') {
                                    return;
                                  }

                                  context.push(
                                    tag.to == 'gallery'
                                        ? "/js_gallery_list"
                                        : '/js_gallery_detail',
                                    extra: GalleryRouteArgs(
                                      title: tag.title ?? '',
                                      url: tag.href ?? '',
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag.title ?? '',
                                    style: theme.typography.overline?.copyWith(
                                      fontSize: 12,
                                      fontFamily: "HarmonyOs Sans SC",
                                      color: theme.accentColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/domain/entities/detail_item.dart';
import 'package:rohos_app/presentation/providers/js_gallery/plugin_info_provider.dart'
    show pluginInfoProvider;
import 'package:rohos_app/presentation/widgets/loading.dart' show Loading;

/// 单张详情卡片。
class DetailCard extends ConsumerWidget {
  const DetailCard({
    super.key,
    required this.item,
    required this.index,
    required this.total,
  });

  final DetailItem item;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = ref.read(
      pluginInfoProvider.select((selector) => selector.value?.headers ?? {}),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.cover != null)
          ExtendedImage.network(
            // item.cover!,
            'https://cdn.pixabay.com/photo/2016/05/31/11/26/baby-1426651_1280.jpg',
            headers: {
              "referrerpolicy": "unsafe-url",
              "referer": item.cover ?? "",
              'user-agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36',
              ...headers,
            },
            handleLoadingProgress: true,
            fit: BoxFit.cover,
            loadStateChanged: (state) {
              if (state.extendedImageLoadState == LoadState.loading) {
                return const Loading(size: 32);
              }
              if (state.extendedImageLoadState == LoadState.failed) {
                return const SizedBox.shrink();
              }
              return null; // 默认显示图片
            },
          ),
      ],
    );
  }
}

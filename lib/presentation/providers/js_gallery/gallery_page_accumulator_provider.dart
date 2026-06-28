import 'package:bot_toast/bot_toast.dart' show BotToast;
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:fwfh_webview/fwfh_webview.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/domain/entities/gallery_accumulator_state.dart';
import 'package:rohos_app/presentation/providers/js_gallery/gallery_provider.dart'
    show galleryProvider;

part 'gallery_page_accumulator_provider.g.dart';

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。
@riverpod
class GalleryPageAccumulator extends _$GalleryPageAccumulator {
  @override
  Future<GalleryAccumulatorState> build(String url) async {
    // url 变化时 Riverpod 自动重新 build，无需手动重置
    ref.onDispose(() {
      iLogger.d('GalleryPageAccumulator: disposed url=$url');
    });
    return GalleryAccumulatorState.empty();
  }

  /// 加载下一页（首次调用相当于加载第 1 页）。
  ///
  /// 如果已在加载中或没有更多页（[GalleryAccumulatorState.hasMore]），
  /// 直接返回不执行。加载完成后通过 [state] 更新 UI。
  Future<void> loadNext() async {
    final current = state.requireValue;
    if (current.isLoading || !current.hasMore) return;

    final nextPage = current.currentPage + 1;
    state = AsyncValue.data(current.copyWith(isLoading: true, error: null));

    try {
      final pageData = await ref.read(
        galleryProvider(url: url, page: nextPage).future,
      );

      if (pageData.needCaptcha == true) {
        BotToast.showText(text: '需要验证码，请在浏览器中访问网站完成验证后再尝试');
        // throw Exception('需要验证码');
        // showHosToast(
        //   // context:  ref.container.,
        //   message: '需要验证码，请在浏览器中访问网站完成验证后再尝试',
        // );
        BotToast.showAnimationWidget(
          toastBuilder: (cancelFunc) {
            return SizedBox(
              width: double.infinity,
              height: 600,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('需要验证码'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        cancelFunc();
                      },
                    ),
                  ],
                ),
                body: HtmlWidget(
                  '''<a>111</a>
                  <iframe src="https://www.baidu.com"></iframe>''',
                  factoryBuilder: () => MyWidgetFactory(),
                ),
              ),
            );
          },
          animationDuration: Duration.zero,
          duration: const Duration(minutes: 5),
        );
        return;
      }

      state = AsyncValue.data(
        GalleryAccumulatorState(
          items: [...current.items, ...pageData.list],
          currentPage: nextPage,
          totalPage: pageData.totalPage,
          isLoading: false,
          error: null,
          hasLoaded: true,
        ),
      );
    } catch (e) {
      iLogger.e('GalleryPageAccumulator: loadNext error: $e');
      state = AsyncValue.data(current.copyWith(isLoading: false, error: e));
    }
  }

  /// 刷新：重置为空状态后重新加载第 1 页。
  Future<void> refresh() async {
    state = AsyncValue.data(GalleryAccumulatorState.empty());
    await loadNext();
  }
}

class MyWidgetFactory extends WidgetFactory with WebViewFactory {}

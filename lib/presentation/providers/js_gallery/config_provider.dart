import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/domain/entities/site_config.dart' show SiteConfig;
import 'package:rohos_app/presentation/providers/init/dio_provider.dart'
    show dioProvider;
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/core/storage/perfs.dart';

// /https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/assets/js/config.json

part 'config_provider.g.dart';

/// 当前选中的 JS 源文件路径（同步），方便各处快速读取。
final selectedSourceProvider = Provider<String?>((ref) {
  return ref.watch(jsConfigProvider).valueOrNull?.name;
});

@riverpod
class JsConfig extends _$JsConfig {
  @override
  Future<JsConfigData> build() async {
    final sites = await getSites();
    // 从 SharedPreferences 读取已保存的选择
    final savedAssets = perfs.getString(perfs.KEY_JS);
    if (savedAssets != null && savedAssets.isNotEmpty) {
      try {
        final jsContent = await loadJsContent(savedAssets);
        console.d(
          "jsConfig: loaded ${sites.length} sites, selected: $savedAssets",
        );
        return JsConfigData(sites, jsContent, savedAssets);
      } catch (e) {
        console.e("加载 JS 内容失败: $savedAssets, error: $e");
      }
    }

    return JsConfigData(sites, '', '');
  }

  /// 切换选中的 JS 源，持久化并重新加载 JS 内容。
  Future<void> select(String assets) async {
    await perfs.putString(perfs.KEY_JS, assets);

    try {
      final jsContent = await loadJsContent(assets);
      state = AsyncValue.data(
        JsConfigData(state.requireValue.sites, jsContent, assets),
      );
    } catch (e) {
      console.e("选择 JS 源后加载内容失败: $assets, error: $e");
      state = AsyncValue.data(
        JsConfigData(state.requireValue.sites, '', assets),
      );
    }
  }

  /// 清除选中的 JS 源。
  void clear() {
    perfs.putString(perfs.KEY_JS, '');
    state = AsyncValue.data(JsConfigData(state.requireValue.sites, '', ''));
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<String> loadJsContent(String assets) async {
    final dio = ref.read(dioProvider);
    try {
      final jsContent = await dio.get(
        "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/$assets",
      );
      return jsContent.data.toString();
    } catch (e) {
      console.e("加载 JS 内容失败: $assets, error: $e");
      return '';
    }
  }

  Future<List<SiteConfig>> getSites() async {
    final dio = ref.watch(dioProvider);
    final result = await dio.get(
      "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/assets/js/config.json",
    );
    final list = jsonDecode(result.data.toString()) as List<dynamic>;
    return list
        .map((e) => SiteConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// JS 配置数据：站点列表、当前选中的 JS 内容和名称。
class JsConfigData {
  final List<SiteConfig> sites;
  final String jsContent;
  final String name;

  JsConfigData(this.sites, this.jsContent, this.name);
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/domain/entities/site_config.dart' show SiteConfig;
import 'package:rohos_app/presentation/providers/init/dio_provider.dart'
    show dioProvider;
import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/core/storage/perfs.dart';

// /https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/assets/js/config.json

part 'config_provider.g.dart';

const String baseUrl = kDebugMode
    ? "http://192.168.2.228:6250/"
    : "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/";

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
      final jsContent = await dio.get("$baseUrl$assets");
      return jsContent.data.toString();
    } catch (e) {
      console.e("加载 JS 内容失败: $assets, error: $e");
      return '';
    }
  }

  Future<List<SiteConfig>> getSites() async {
    final dio = ref.watch(dioProvider);
    final result = await dio.get("${baseUrl}assets/js/config.json");
    final list = _parseConfigList(result.data.toString());
    return list
        .map((e) => SiteConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 解析配置列表，兼容标准 JSON 和 JS 对象字面量两种格式。
  ///
  /// JS 格式示例: `[{title: 美图乐, assets: "meitule.js"}]`
  /// JSON 格式:   `[{"title": "美图乐", "assets": "meitule.js"}]`
  List<dynamic> _parseConfigList(String raw) {
    // 先尝试标准 JSON 解析
    try {
      return jsonDecode(raw.trim()) as List<dynamic>;
    } on FormatException {
      // 忽略，继续尝试 JS 字面量转换
    }

    // JS 对象字面量 → JSON 转换
    var text = raw.trim();
    if (text.endsWith(';')) text = text.substring(0, text.length - 1);

    // 单引号 → 双引号
    text = text.replaceAll("'", '"');

    // 给未加引号的 key 加双引号: {title: → {"title":
    text = text.replaceAllMapped(
      RegExp(r'(\{|\,)\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\:)'),
      (m) => '${m[1]}"${m[2]}"',
    );

    // 给未加引号的字符串值加双引号
    text = text.replaceAllMapped(
      RegExp(r'(?<=\:\s*)([^"\,\]\}\s][^"\,\]\}\n\r]*?)(?=\s*[\},\]])'),
      (m) {
        final v = m[1]!.trim();
        if (v == 'true' || v == 'false' || v == 'null') return v;
        if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v)) return v;
        return '"$v"';
      },
    );

    return jsonDecode(text) as List<dynamic>;
  }
}

/// JS 配置数据：站点列表、当前选中的 JS 内容和名称。
class JsConfigData {
  final List<SiteConfig> sites;
  final String jsContent;
  final String name;

  JsConfigData(this.sites, this.jsContent, this.name);
}

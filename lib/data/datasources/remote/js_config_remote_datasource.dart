import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:rohos_app/core/utils/logger.dart';
import 'package:rohos_app/domain/entities/site_config.dart';

/// JS 配置远程数据源。
///
/// 负责从 GitHub 获取 config.json 和 JS 文件内容。
class JsConfigRemoteDataSource {
  final Dio _dio;

  static const _baseUrl =
      "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master";

  const JsConfigRemoteDataSource(this._dio);

  /// 获取站点配置列表。
  Future<List<SiteConfig>> getSites() async {
    final result = await _dio.get("$_baseUrl/assets/js/config.json");
    final list = jsonDecode(result.data.toString()) as List<dynamic>;
    return list
        .map((e) => SiteConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 加载指定路径的 JS 内容。
  Future<String> loadJsContent(String assets) async {
    final dio = _dio;
    try {
      final jsContent = await dio.get("$_baseUrl/$assets");
      return jsContent.data.toString();
    } catch (e) {
      iLogger.e("加载 JS 内容失败: $assets, error: $e");
      return '';
    }
  }
}

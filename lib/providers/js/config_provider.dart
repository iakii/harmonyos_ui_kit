import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/models/plugin/site_config.dart' show SiteConfig;
import 'package:rohos_app/providers/dio_provider.dart' show dioProvider;
import 'package:rohos_app/providers/js/settings_provider.dart'
    show jsSourceProvider;
// /https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/assets/js/config.json

part 'config_provider.g.dart';

@riverpod
Future<JsConfig> jsConfig(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final assets = ref.watch(jsSourceProvider);
  final result = await dio.get(
    "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/assets/js/config.json",
  );

  final list = jsonDecode(result.data.toString()) as List<dynamic>;
  final sites = list
      .map((e) => SiteConfig.fromJson(e as Map<String, dynamic>))
      .toList();

  if (assets != null && assets.isNotEmpty) {
    final jsContent = await dio.get(
      "https://gh-proxy.org/https://raw.githubusercontent.com/iakii/harmonyos_ui_kit/refs/heads/master/$assets",
    );
    return JsConfig(sites, jsContent.data.toString(), assets);
  }

  return JsConfig(sites, '', assets ?? '');
}

class JsConfig {
  final List<SiteConfig> sites;
  final String jsContent;
  final String name;

  JsConfig(this.sites, this.jsContent, this.name);
}

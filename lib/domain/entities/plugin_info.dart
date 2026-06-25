import 'menu_item.dart';

/// 插件信息，对应 meitule.js 中 client.pluginInfo 返回的 JSON。
class PluginInfo {
  final String type;
  final String version;
  final String website;
  final String name;
  final List<MenuItem> menus;
  final String? icon;
  final Map<String, dynamic>? headers;

  const PluginInfo({
    required this.type,
    required this.version,
    required this.website,
    required this.name,
    required this.menus,
    this.icon,
    this.headers,
  });

  factory PluginInfo.fromJson(Map<String, dynamic> json) => PluginInfo(
    type: json['type'] as String? ?? '',
    version: json['version'] as String? ?? '',
    website: json['website'] as String? ?? '',
    name: json['name'] as String? ?? '',
    icon: json['icon'] as String?,
    headers: json['headers'] as Map<String, dynamic>?,
    menus:
        (json['menus'] as List<dynamic>?)
            ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

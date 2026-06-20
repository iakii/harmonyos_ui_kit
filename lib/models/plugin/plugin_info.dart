/// 菜单项，对应 meitule.js 中 pluginInfo.menus 的每个元素。
class MenuItem {
  final String label;
  final String path;

  const MenuItem({required this.label, required this.path});

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        label: json['label'] as String? ?? '',
        path: json['path'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'label': label, 'path': path};
}

/// 插件信息，对应 meitule.js 中 client.pluginInfo 返回的 JSON。
class PluginInfo {
  final String type;
  final String version;
  final String website;
  final String name;
  final List<MenuItem> menus;

  const PluginInfo({
    required this.type,
    required this.version,
    required this.website,
    required this.name,
    required this.menus,
  });

  factory PluginInfo.fromJson(Map<String, dynamic> json) => PluginInfo(
        type: json['type'] as String? ?? '',
        version: json['version'] as String? ?? '',
        website: json['website'] as String? ?? '',
        name: json['name'] as String? ?? '',
        menus: (json['menus'] as List<dynamic>?)
                ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

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

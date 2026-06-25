/// 站点配置项，对应 config.json 中的每个元素。
class SiteConfig {
  final String title;
  final String assets;

  const SiteConfig({required this.title, required this.assets});

  factory SiteConfig.fromJson(Map<String, dynamic> json) => SiteConfig(
    title: json['title'] as String? ?? '',
    assets: json['assets'] as String? ?? '',
  );
}

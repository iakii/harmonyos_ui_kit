/// 图集路由参数（用于 js_gallery_detail / js_gallery_list / js_intro 路由）。
class GalleryRouteArgs {
  final String url;
  final String title;

  const GalleryRouteArgs({required this.url, this.title = ''});

  Map<String, dynamic> toJson() => {'url': url, 'title': title};
}

/// Rust Daily 路由参数（用于 /rust 路由，type=detail 时跳转详情页）。
class RustDailyRouteArgs {
  final String url;
  final String type;
  final String title;

  const RustDailyRouteArgs({
    required this.url,
    required this.type,
    this.title = '',
  });

  Map<String, dynamic> toJson() => {'url': url, 'type': type, 'title': title};
}

import 'package:rohos_app/domain/entities/site_config.dart';

/// JS 配置数据。
class JsConfigData {
  final List<SiteConfig> sites;
  final String jsContent;
  final String name;

  JsConfigData(this.sites, this.jsContent, this.name);
}

/// JS 配置仓库接口。
///
/// 负责管理 JS 源选择、远程加载和本地持久化。
abstract class JsConfigRepository {
  /// 获取所有可用的 JS 站点配置。
  Future<List<SiteConfig>> getSites();

  /// 加载指定路径的 JS 内容。
  Future<String> loadJsContent(String assets);

  /// 选中 JS 源（持久化并加载内容），返回 [JsConfigData]。
  Future<JsConfigData> select(String assets);

  /// 清除选中的 JS 源。
  Future<void> clear();
}

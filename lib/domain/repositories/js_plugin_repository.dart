import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';

/// JS 插件信息仓库接口。
///
/// 负责通过 JsEngine 获取当前 JS 插件的元信息。
abstract class JsPluginRepository {
  /// 获取插件元信息。
  Future<Result<PluginInfo>> getPluginInfo();
}

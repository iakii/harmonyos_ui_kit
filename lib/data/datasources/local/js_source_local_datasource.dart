import 'package:rohos_app/core/storage/perfs.dart';

/// JS 源本地数据源。
///
/// 负责通过 SharedPreferences 持久化和读取 JS 源选择。
class JsSourceLocalDataSource {
  /// 获取已保存的 JS 源路径。
  String? getSavedSource() => perfs.getString(perfs.KEY_JS);

  /// 保存 JS 源路径。
  Future<void> saveSource(String value) => perfs.putString(perfs.KEY_JS, value);

  /// 清除已保存的 JS 源路径。
  Future<void> clearSource() => perfs.putString(perfs.KEY_JS, '');
}

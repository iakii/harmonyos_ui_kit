import 'package:rohos_app/domain/repositories/js_config_repository.dart';

/// 选择并加载 JS 源用例。
///
/// 协调远程加载（从 GitHub 下载 JS 内容）和本地持久化（SharedPreferences）。
class SelectJsSource {
  final JsConfigRepository _repository;

  const SelectJsSource(this._repository);

  /// 选择 JS 源，持久化并加载内容。
  Future<JsConfigData> call(String assets) {
    return _repository.select(assets);
  }
}
